# Aplicacion y API

Este directorio contiene los dos componentes de HOTFTP: `frontend/` (Flutter) y `backend/` (Node.js, Express y TypeScript), además de `render.yaml`.

La guia principal de instalacion, configuracion y ejecucion esta en el [README del repositorio](../../README.md).

## Configuracion local

En `backend/`, copia `.env.example` a `.env` y completa los valores para tu entorno. No publiques ese archivo ni compartas credenciales. Para iniciar la API:

```bash
npm ci
npm run dev
```

Para iniciar el cliente, instala las dependencias Flutter y define `HOTFTP_API_BASE_URL` con la dirección de la API.
