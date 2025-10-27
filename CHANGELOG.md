# Changelog - JS-Framework

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]
Dado que el proyecto parte de un sistema ya funcional, iré incorporando aquí las modificaciones realizadas sobre el código ya existente

### En Desarrollo a corto plazo
- Soporte completo para diversos gestores de BBDD (SQLite, Firebird, PostgreSQL, …)

## [0.1.0-alpha] - 2025-10-25

### Añadido
- Implementación inicial de `TEntity` como clase base
- Sistema de estados: `TEntityState` (esNew, esUnchanged, esModified, esDeleted)
- Sistema de metadata: `TEntityMetadata` (CreatedAt, ModifiedAt, CreatedBy, ModifiedBy, Version)
- Sistema de validación: `TValidationMessage` y `TValidationMessages`
- Métodos `Validate`, `IsValid`, `MarkAsModified`, `MarkAsDeleted`
- `BeginLoad` / `EndLoad` para carga sin efectos secundarios
- Helpers de campo: `SetFieldString`, `SetFieldInteger`, `SetFieldBoolean`
- `TEntitySerializer`: Helper para serialización type-safe a JSON
- `TEntityDeserializer`: Helper para deserialización type-safe desde JSON
- Hooks virtuales `DoSerializeFields` / `DoDeserializeFields`
- Serialización JSON: `ToJSONString`, `FromJSONString`
- Tests unitarios con FPCUnit (separados por responsabilidad)

## Categorías de Cambios

- `Añadido` para nuevas funcionalidades
- `Cambiado` para cambios en funcionalidad existente
- `Deprecado` para funcionalidades que serán eliminadas
- `Eliminado` para funcionalidades eliminadas
- `Corregido` para corrección de bugs
- `Seguridad` para vulnerabilidades corregidas
- `Mejorado` para mejoras de rendimiento o calidad
