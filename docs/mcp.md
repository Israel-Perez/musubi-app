# MCP del equipo (Model Context Protocol)

La app usa los mismos MCP que la API. La configuración paso a paso (Claude Code y OpenCode) y las reglas están en [`musubi-api/docs/mcp.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/mcp.md); aquí solo va cómo se usan del lado de la app.

| MCP | Para qué se usa en la app | Configuración |
|---|---|---|
| **Atlassian (Jira y Confluence)** | Cada spec y PR lleva su clave `SCRUM-NN`. El agente lee la HU, comenta el avance con evidencia (pruebas, PR, versión de Play) y la transiciona (`21` En curso, `31` En revisión, `41` Finalizado). La página de la HU va en Confluence | Servidor remoto `https://mcp.atlassian.com/v1/sse` con OAuth en el navegador |
| **AWS (`aws-mcp`)** | Consultar la API desplegada cuando una pantalla falla en producción: logs de CloudWatch y estado del despliegue | `uvx mcp-proxy-for-aws@latest https://aws-mcp.us-east-1.api.aws/mcp`, con las credenciales de `aws login` |
| **GitHub** (CLI `gh`, no MCP) | PR, checks del CI, workflow `release-play` | `gh auth login` |

## Reglas

- Ningún MCP guarda credenciales en el repo: se entra por OAuth o con las credenciales locales de cada quien.
- Lo que un agente escribe en Jira o Confluence lo ve todo el equipo: antes de hacerlo, lo dice en el chat.
- Publicar en Google Play o desplegar la API siempre pasa por los workflows (`release-play`, `infra-up`), nunca por un MCP.
