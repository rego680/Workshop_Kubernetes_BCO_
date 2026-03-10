# Lab 2 - JSON Web Token (JWT)

## ¿Qué es un JWT?

Un **JSON Web Token (JWT)** es un estándar abierto (RFC 7519) que define un formato compacto y seguro para transmitir información entre dos partes como un objeto JSON firmado digitalmente.

Un JWT se compone de tres partes separadas por puntos (`.`):

```
HEADER.PAYLOAD.SIGNATURE
```

| Parte | Contenido |
|-------|-----------|
| **Header** | Algoritmo de firma y tipo de token |
| **Payload** | Claims (datos del usuario, roles, expiración, etc.) |
| **Signature** | Firma que garantiza la integridad del token |

## Analizar un JWT

En este laboratorio se incluye el archivo `JWT.txt` con un token de ejemplo. Para analizarlo:

1. Abre [https://token.dev/](https://token.dev/) en tu navegador.
2. Copia el contenido del archivo `JWT.txt` y pégalo en el campo de entrada.
3. La herramienta decodificará automáticamente el Header y el Payload, mostrando los claims del token como `sub`, `role`, `exp`, entre otros.

> **Nota:** La firma solo puede verificarse si se conoce el secreto o la clave pública con la que fue generado el token.
