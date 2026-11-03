import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/shake.dart';
import 'package:musubi_app/features/listings/data/photo_picker.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';

/// "Datos personales" (maqueta `Ajustes`, `aj-datos`): el nombre viene del
/// correo verificado y no se edita; la carrera y el cuatrimestre se eligen de
/// listas del campus (la maqueta los escribe a mano). La foto es un agregado
/// de HU-04 (lineamiento 4).
Future<void> showPersonalDataSheet(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = await showMusubiPanel<bool>(
    context,
    builder: (_) => const PersonalDataSheet(),
  );
  if (saved ?? false) showMusubiSnack(messenger, 'Guardamos tus datos');
}

class PersonalDataSheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PersonalDataSheet> createState() => _PersonalDataSheetState();
}

class _PersonalDataSheetState extends ConsumerState<PersonalDataSheet> {
  late final MyProfile? _initial = ref.read(myProfileProvider).value;
  late Career? _career = _initial?.career;
  late int? _term = _initial?.term;
  late final _name = TextEditingController(text: _initial?.fullName ?? '');

  /// El cuatrimestre se borro porque no cabe en la carrera nueva.
  bool _termCleared = false;
  bool _saving = false;
  bool _uploading = false;
  String? _error;
  int _shake = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCareer(CareersCatalog catalog) async {
    final picked = await showMusubiPanel<(Career?,)>(
      context,
      builder: (_) => _CareerPicker(catalog: catalog, selected: _career),
    );
    if (picked == null || !mounted) return;
    final (career,) = picked;
    setState(() {
      _career = career;
      _termCleared = false;
      final term = _term;
      if (term != null && !catalog.termsFor(career).contains(term)) {
        _term = null;
        _termCleared = true;
      }
    });
  }

  Future<void> _pickTerm(CareersCatalog catalog) async {
    final unit = catalog.academicTerm.unit;
    final picked = await showMusubiPanel<(int?,)>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('term-picker'),
        title: _capitalize(unit),
        bodyInset: 12,
        child: MusubiOptions<int>(
          selected: _term ?? 0,
          options: [
            MusubiOption(value: 0, label: 'Sin $unit'),
            for (final t in catalog.termsFor(_career))
              MusubiOption(value: t, label: catalog.academicTerm.label(t)),
          ],
          onPick: (t) => Navigator.of(context).pop((t == 0 ? null : t,)),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _term = picked.$1;
      _termCleared = false;
    });
  }

  Future<void> _changePhoto() async {
    final hasPhoto = ref.read(myProfileProvider).value?.photoUrl != null;
    final action = await showMusubiPanel<String>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('photo-options'),
        title: 'Foto de perfil',
        bodyInset: 12,
        child: MusubiOptions<String>(
          plain: true,
          options: [
            const MusubiOption(
              value: 'camera',
              label: 'Tomar foto',
              icon: MusubiIcons.camera,
            ),
            const MusubiOption(
              value: 'gallery',
              label: 'Elegir de la galería',
              icon: MusubiIcons.image,
            ),
            if (hasPhoto)
              const MusubiOption(
                value: 'remove',
                label: 'Quitar foto',
                icon: MusubiIcons.trash,
                danger: true,
              ),
          ],
          onPick: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (action == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final profile = ref.read(myProfileProvider.notifier);
    try {
      if (action == 'remove') {
        setState(() => _uploading = true);
        await profile.removePhoto();
        showMusubiSnack(messenger, 'Quitamos tu foto', tone: SnackTone.info);
        return;
      }
      final picker = ref.read(photoPickerProvider);
      final path = action == 'camera'
          ? await picker.takePhoto()
          : (await picker.pickFromGallery(max: 1)).firstOrNull;
      if (path == null || !mounted) return;
      setState(() => _uploading = true);
      await profile.uploadPhoto(path);
      showMusubiSnack(messenger, 'Actualizamos tu foto');
    } on PhotoPickFailure {
      showMusubiSnack(
        messenger,
        action == 'camera'
            ? 'No pudimos abrir la cámara.'
            : 'No pudimos abrir tu galería.',
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    } on ApiFailure catch (failure) {
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(myProfileProvider.notifier)
          .save(career: _career?.slug, term: _term);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
        _shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(myProfileProvider).value ?? _initial;
    final careers = ref.watch(careersProvider);
    final catalog = careers.value;
    final unit = catalog?.academicTerm.unit ?? me?.academicTerm.unit;
    return MusubiPanel(
      key: const Key('personal-data-sheet'),
      title: 'Datos personales',
      tall: true,
      actions: [
        MusubiButton(
          key: const Key('personal-data-save'),
          label: 'Guardar cambios',
          loadingLabel: 'Guardando…',
          loading: _saving,
          height: MusubiSizes.buttonHeightSheet,
          onPressed: catalog == null || _uploading ? null : _save,
        ),
        MusubiButton(
          label: 'Cancelar',
          kind: MusubiButtonKind.quiet,
          height: 46,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: ProfileAvatar(
              key: const Key('personal-data-avatar'),
              initials: me?.initials ?? '',
              photoUrl: me?.photoUrl,
              size: 84,
              fontSize: 28,
              uploading: _uploading,
            ),
          ),
          Center(
            child: MusubiButton(
              key: const Key('personal-data-photo'),
              label: _uploading ? 'Subiendo foto…' : 'Cambiar foto',
              kind: MusubiButtonKind.link,
              icon: MusubiIcons.camera,
              expand: false,
              onPressed: _uploading || _saving ? null : _changePhoto,
            ),
          ),
          MusubiTextField(
            label: 'Nombre',
            controller: _name,
            enabled: false,
            fieldKey: const Key('personal-data-name'),
            sheet: true,
            footer: const _Small(
              'Viene de tu correo institucional verificado.',
            ),
          ),
          const SizedBox(height: 12),
          _SelectField(
            key: const Key('personal-data-career'),
            label: 'Carrera',
            value: _career?.shortName,
            placeholder: switch (careers) {
              AsyncError() => 'No pudimos cargar las carreras',
              AsyncData() => 'Elige tu carrera',
              _ => 'Cargando carreras…',
            },
            onTap: catalog == null || _saving
                ? (careers.hasError
                      ? () => ref.invalidate(careersProvider)
                      : null)
                : () => _pickCareer(catalog),
          ),
          const SizedBox(height: 12),
          _SelectField(
            key: const Key('personal-data-term'),
            label: _capitalize(unit ?? 'cuatrimestre'),
            value: _term == null ? null : me?.academicTerm.label(_term!),
            placeholder: 'Elige tu $unit',
            note: _termCleared
                ? 'El que tenías no corresponde a esta carrera: elige otro.'
                : null,
            onTap: catalog == null || _saving ? null : () => _pickTerm(catalog),
          ),
          if (_error != null)
            Shake(
              trigger: _shake,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FieldMessage(text: _error!),
              ),
            ),
        ],
      ),
    );
  }
}

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Ayuda bajo un campo (`.s-field small`): 12.5, peso 600 y gris.
class _Small extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: MusubiType.style(
      12.5,
      weight: FontWeight.w600,
      line: 22,
      color: context.musubi.textSecondary,
    ),
  );
}

/// Campo que abre una lista (carrera, cuatrimestre): misma caja de 52 que
/// `.s-field input`, con el valor elegido o el texto de ayuda en gris y la
/// flecha hacia abajo.
class _SelectField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    super.key,
    this.note,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  /// Aviso bajo la caja (el cuatrimestre se borro).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        SizedBox(
          height: 22,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: MusubiType.style(
                13,
                weight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
        Pressable(
          onTap: onTap,
          semanticLabel: '$label: ${value ?? placeholder}',
          builder: (context, pressed) => Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
            decoration: BoxDecoration(
              color: pressed ? c.surface : c.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: note == null ? c.border : c.warning,
                width: 1.5,
              ),
            ),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: MusubiType.style(
                      16,
                      weight: FontWeight.w600,
                      line: 22,
                      color: value == null ? c.placeholder : c.textPrimary,
                    ),
                  ),
                ),
                MusubiIcon(MusubiIcons.chevronDown, size: 20, color: c.chevron),
              ],
            ),
          ),
        ),
        if (note != null) FieldMessage(text: note!, color: c.warningText),
      ],
    );
  }
}

/// Lista de carreras con buscador, agrupada en TSU, Ingeniería y
/// Licenciatura, con "Sin carrera" al inicio. Devuelve `(carrera,)`.
class _CareerPicker extends StatefulWidget {
  const new({required this.catalog, required this.selected});

  final CareersCatalog catalog;
  final Career? selected;

  @override
  State<_CareerPicker> createState() => _CareerPickerState();
}

class _CareerPickerState extends State<_CareerPicker> {
  String _query = '';

  static String _fold(String text) => text
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u');

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final query = _fold(_query.trim());
    final matches = widget.catalog.careers
        .where(
          (career) =>
              query.isEmpty ||
              _fold(career.name).contains(query) ||
              _fold(career.shortName).contains(query),
        )
        .toList();
    void pick(String slug) => Navigator.of(context).pop((
      widget.catalog.careers.where((career) => career.slug == slug).firstOrNull,
    ));
    return MusubiPanel(
      key: const Key('career-picker'),
      title: 'Carrera',
      tall: true,
      bodyInset: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: MusubiTextField(
              label: 'Buscar',
              hint: 'Escribe parte del nombre',
              prefixIcon: MusubiIcons.search,
              fieldKey: const Key('career-search'),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          if (query.isEmpty)
            MusubiOptions<String>(
              selected: widget.selected?.slug ?? '',
              options: const [MusubiOption(value: '', label: 'Sin carrera')],
              onPick: pick,
            ),
          for (final level in CareerLevel.values)
            if (matches.any((career) => career.level == level)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 4),
                child: Text(
                  level.label.toUpperCase(),
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w800,
                    line: 16,
                    em: 0.08,
                    color: c.textSecondary,
                  ),
                ),
              ),
              MusubiOptions<String>(
                selected: widget.selected?.slug ?? '',
                options: [
                  for (final career in matches)
                    if (career.level == level)
                      MusubiOption(value: career.slug, label: career.name),
                ],
                onPick: pick,
              ),
            ],
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
              child: Text(
                'No encontramos esa carrera. Si no está en la lista, '
                'escríbenos a contacto@musubiapp.com.mx.',
                style: MusubiType.style(14, line: 20, color: c.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
