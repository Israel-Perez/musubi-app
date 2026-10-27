// Iconos Lucide (ISC, assets/licenses/lucide.txt) copiados de las pantallas
// de la maqueta (docs/maqueta/musubi-prototipo.html): mismo trazo y mismas
// coordenadas. El grosor del trazo va en cada uso, como en la maqueta.
import 'package:musubi_app/core/widgets/musubi_icon.dart';

/// Iconos de la maqueta para [MusubiIcon].
abstract final class MusubiIcons {
  /// `arrow-right`.
  static const arrowRight = MusubiIconData([
    IconPath('M5 12h14'),
    IconPath('m12 5 7 7-7 7'),
  ]);

  /// `badge-check (relleno)`.
  static const badgeCheck = MusubiIconData([
    IconPath(
      'M3.85 8.62a4 4 0 0 1 4.78-4.77 4 4 0 0 1 6.74 0 4 4 0 0 1 4.78 4.78 4 4 '
      '0 0 1 0 6.74 4 4 0 0 1-4.77 4.78 4 4 0 0 1-6.75 0 4 4 0 0 1-4.78-4.77 4 '
      '4 0 0 1 0-6.76Z',
      fill: true,
    ),
    IconPath('m8.5 12 2.5 2.5 4.5-5'),
  ]);

  /// `ban`.
  static const ban = MusubiIconData([
    IconCircle(12, 12, 10),
    IconPath('m4.9 4.9 14.2 14.2'),
  ]);

  /// `bell`.
  static const bell = MusubiIconData([
    IconPath('M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9'),
    IconPath('M10.3 21a1.94 1.94 0 0 0 3.4 0'),
  ]);

  /// `book-open`.
  static const bookOpen = MusubiIconData([
    IconPath('M12 7v14'),
    IconPath(
      'M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 '
      '0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z',
    ),
  ]);

  /// `calendar`.
  static const calendar = MusubiIconData([
    IconRect(3, 4, 18, 18, radius: 2),
    IconPath('M16 2v4'),
    IconPath('M8 2v4'),
    IconPath('M3 10h18'),
  ]);

  /// `camera`.
  static const camera = MusubiIconData([
    IconPath(
      'M14.5 4h-5L7 7H4a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2V9a2 2 0 '
      '0 0-2-2h-3l-2.5-3z',
    ),
    IconCircle(12, 13, 3),
  ]);

  /// `check`.
  static const check = MusubiIconData([IconPath('M20 6 9 17l-5-5')]);

  /// `chevron-down`.
  static const chevronDown = MusubiIconData([IconPath('m6 9 6 6 6-6')]);

  /// `chevron-left`.
  static const chevronLeft = MusubiIconData([IconPath('m15 18-6-6 6-6')]);

  /// `chevron-right`.
  static const chevronRight = MusubiIconData([IconPath('m9 18 6-6-6-6')]);

  /// `circle-alert`.
  static const circleAlert = MusubiIconData([
    IconCircle(12, 12, 10),
    IconPath('M12 8v4'),
    IconPath('M12 16h.01'),
  ]);

  /// `circle-check`.
  static const circleCheck = MusubiIconData([
    IconCircle(12, 12, 10),
    IconPath('m9 12 2 2 4-4'),
  ]);

  /// `clock`.
  static const clock = MusubiIconData([
    IconCircle(12, 12, 10),
    IconPath('M12 6v6l4 2'),
  ]);

  /// `database`.
  static const database = MusubiIconData([
    IconEllipse(12, 5, 9, 3),
    IconPath('M3 5v14a9 3 0 0 0 18 0V5'),
    IconPath('M3 12a9 3 0 0 0 18 0'),
  ]);

  /// `signo de admiracion (Inicio-error)`.
  static const exclamation = MusubiIconData([
    IconPath('M12 7v6'),
    IconPath('M12 17h.01'),
  ]);

  /// `external-link`.
  static const externalLink = MusubiIconData([
    IconPath('M15 3h6v6'),
    IconPath('M10 14 21 3'),
    IconPath('M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6'),
  ]);

  /// `eye`.
  static const eye = MusubiIconData([
    IconPath(
      'M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 '
      '.696 10.75 10.75 0 0 1-19.876 0',
    ),
    IconCircle(12, 12, 3),
  ]);

  /// `file-text`.
  static const fileText = MusubiIconData([
    IconPath('M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z'),
    IconPath('M14 2v4a2 2 0 0 0 2 2h4'),
    IconPath('M10 9H8'),
    IconPath('M16 13H8'),
    IconPath('M16 17H8'),
  ]);

  /// `flame`.
  static const flame = MusubiIconData([
    IconPath(
      'M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 '
      '2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 '
      '0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z',
    ),
  ]);

  /// `flask-conical`.
  static const flaskConical = MusubiIconData([
    IconPath(
      'M10 2v7.53a2 2 0 0 1-.21.9L4.72 20.55a1 1 0 0 0 .9 1.45h12.76a1 1 0 0 0 '
      '.9-1.45l-5.07-10.12a2 2 0 0 1-.21-.9V2',
    ),
    IconPath('M8.5 2h7'),
    IconPath('M7 16h10'),
  ]);

  /// `graduation-cap`.
  static const graduationCap = MusubiIconData([
    IconPath(
      'M21.42 10.922a1 1 0 0 0-.019-1.838L12.83 5.18a2 2 0 0 0-1.66 0L2.6 '
      '9.08a1 1 0 0 0 0 1.832l8.57 3.908a2 2 0 0 0 1.66 0z',
    ),
    IconPath('M22 10v6'),
    IconPath('M6 12.5V16a6 3 0 0 0 12 0v-3.5'),
  ]);

  /// `hand`.
  static const hand = MusubiIconData([
    IconPath('M18 11V6a2 2 0 0 0-2-2a2 2 0 0 0-2 2'),
    IconPath('M14 10V4a2 2 0 0 0-2-2a2 2 0 0 0-2 2v2'),
    IconPath('M10 10.5V6a2 2 0 0 0-2-2a2 2 0 0 0-2 2v8'),
    IconPath(
      'M18 8a2 2 0 1 1 4 0v6a8 8 0 0 1-8 8h-2c-2.8 '
      '0-4.5-.86-5.99-2.34l-3.6-3.6a2 2 0 0 1 2.83-2.82L7 15',
    ),
  ]);

  /// `heart`.
  static const heart = MusubiIconData([
    IconPath(
      'M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 '
      '2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z',
    ),
  ]);

  /// `house`.
  static const house = MusubiIconData([
    IconPath('M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8'),
    IconPath(
      'M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 '
      '21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z',
    ),
  ]);

  /// `info`.
  static const info = MusubiIconData([
    IconCircle(12, 12, 10),
    IconPath('M12 16v-4'),
    IconPath('M12 8h.01'),
  ]);

  /// `laptop`.
  static const laptop = MusubiIconData([
    IconPath(
      'M20 16V7a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v9m16 0H4m16 0 1.28 2.55a1 1 0 0 '
      '1-.9 1.45H3.62a1 1 0 0 1-.9-1.45L4 16',
    ),
  ]);

  /// `layout-grid`.
  static const layoutGrid = MusubiIconData([
    IconRect(3, 3, 7, 7, radius: 1.5),
    IconRect(14, 3, 7, 7, radius: 1.5),
    IconRect(14, 14, 7, 7, radius: 1.5),
    IconRect(3, 14, 7, 7, radius: 1.5),
  ]);

  /// `lock`.
  static const lock = MusubiIconData([
    IconRect(3, 11, 18, 11, radius: 2),
    IconPath('M7 11V7a5 5 0 0 1 10 0v4'),
  ]);

  /// `log-out`.
  static const logOut = MusubiIconData([
    IconPath('M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4'),
    IconPath('m16 17 5-5-5-5'),
    IconPath('M21 12H9'),
  ]);

  /// `mail`.
  static const mail = MusubiIconData([
    IconRect(2, 4, 20, 16, radius: 2),
    IconPath('m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7'),
  ]);

  /// `mail-check`.
  static const mailCheck = MusubiIconData([
    IconPath('M22 13V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v12c0 1.1.9 2 2 2h8'),
    IconPath('m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7'),
    IconPath('m16 19 2 2 4-4'),
  ]);

  /// `megaphone`.
  static const megaphone = MusubiIconData([
    IconPath('m3 11 18-5v12L3 14v-3z'),
    IconPath('M11.6 16.8a3 3 0 1 1-5.8-1.6'),
  ]);

  /// `message-circle`.
  static const messageCircle = MusubiIconData([
    IconPath('M7.9 20A9 9 0 1 0 4 16.1L2 22Z'),
  ]);

  /// `moon`.
  static const moon = MusubiIconData([
    IconPath('M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z'),
  ]);

  /// `pen-line`.
  static const penLine = MusubiIconData([
    IconPath('M12 20h9'),
    IconPath('M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z'),
  ]);

  /// `plus`.
  static const plus = MusubiIconData([
    IconPath('M5 12h14'),
    IconPath('M12 5v14'),
  ]);

  /// `refresh-cw`.
  static const refreshCw = MusubiIconData([
    IconPath('M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8'),
    IconPath('M21 3v5h-5'),
    IconPath('M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16'),
    IconPath('M8 16H3v5'),
  ]);

  /// `search`.
  static const search = MusubiIconData([
    IconCircle(11, 11, 8),
    IconPath('m21 21-4.3-4.3'),
  ]);

  /// `settings`.
  static const settings = MusubiIconData([
    IconPath(
      'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 '
      '0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 '
      '1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 '
      '2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 '
      '2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 '
      '0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 '
      '1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 '
      '0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 '
      '0-2-2z',
    ),
    IconCircle(12, 12, 3),
  ]);

  /// `shield-check`.
  static const shieldCheck = MusubiIconData([
    IconPath(
      'M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 '
      '0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 '
      '19 5a1 1 0 0 1 1 1z',
    ),
    IconPath('m9 12 2 2 4-4'),
  ]);

  /// `shopping-bag`.
  static const shoppingBag = MusubiIconData([
    IconPath('M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z'),
    IconPath('M3 6h18'),
    IconPath('M16 10a4 4 0 0 1-8 0'),
  ]);

  /// `sliders-horizontal`.
  static const slidersHorizontal = MusubiIconData([
    IconPath('M21 4h-7'),
    IconPath('M10 4H3'),
    IconPath('M21 12h-9'),
    IconPath('M8 12H3'),
    IconPath('M21 20h-5'),
    IconPath('M12 20H3'),
    IconPath('M14 2v4'),
    IconPath('M8 10v4'),
    IconPath('M16 18v4'),
  ]);

  /// `star (relleno)`.
  static const star = MusubiIconData([
    IconPath(
      'M12 2.5l2.94 5.96 6.56.95-4.75 4.63 1.12 6.54L12 17.5l-5.87 3.08 '
      '1.12-6.54L2.5 9.41l6.56-.95z',
      fill: true,
    ),
  ]);

  /// `triangle-alert`.
  static const triangleAlert = MusubiIconData([
    IconPath(
      'm21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 '
      '1.73-3',
    ),
    IconPath('M12 9v4'),
    IconPath('M12 17h.01'),
  ]);

  /// `undo-2`.
  static const undo2 = MusubiIconData([
    IconPath('M9 14 4 9l5-5'),
    IconPath('M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5a5.5 5.5 0 0 1-5.5 5.5H11'),
  ]);

  /// `user`.
  static const user = MusubiIconData([
    IconPath('M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2'),
    IconCircle(12, 7, 4),
  ]);

  /// `user-round`.
  static const userRound = MusubiIconData([
    IconCircle(12, 8, 5),
    IconPath('M20 21a8 8 0 0 0-16 0'),
  ]);

  /// `wifi-off`.
  static const wifiOff = MusubiIconData([
    IconPath('M12 20h.01'),
    IconPath('M8.5 16.43a5 5 0 0 1 7 0'),
    IconPath('M5 12.86a10 10 0 0 1 5.17-2.69'),
    IconPath('M19 12.86a10 10 0 0 0-2.01-1.52'),
    IconPath('M2 8.82a15 15 0 0 1 4.18-2.64'),
    IconPath('M22 8.82a15 15 0 0 0-11.29-3.76'),
    IconPath('m2 2 20 20'),
  ]);

  /// `x`.
  static const x = MusubiIconData([
    IconPath('M18 6 6 18'),
    IconPath('m6 6 12 12'),
  ]);

  /// `eye-off` (Lucide; la maqueta solo muestra el ojo abierto).
  static const eyeOff = MusubiIconData([
    IconPath(
      'M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 '
      '10.747 10.747 0 0 1-1.444 2.49',
    ),
    IconPath('M14.084 14.158a3 3 0 0 1-4.242-4.242'),
    IconPath(
      'M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 '
      '10.75 10.75 0 0 1 4.446-5.143',
    ),
    IconPath('m2 2 20 20'),
  ]);

  /// Arco que gira en un boton que esta cargando (`loadingButton`).
  static const spinner = MusubiIconData([
    IconPath('M21 12a9 9 0 1 1-6.22-8.56'),
  ]);
}
