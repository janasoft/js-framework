# JS-Framework - Framework de Entidades para Free Pascal/Lazarus

⚠️ **Estado: Alpha / Desarrollo Activo**

Framework moderno para desarrollo de aplicaciones desktop y web en Free Pascal/Lazarus, siguiendo principios SOLID y buenas prácticas de diseño orientado a objetos.

**JS-Framework** es desarrollado por **Janasoft**.

## 🎯 Objetivo

Proporcionar una capa de abstracción robusta y flexible para el manejo de entidades de negocio, soportando:
- Aplicaciones de escritorio (Lazarus/LCL)
- APIs web (vía serialización JSON)
- Múltiples motores de base de datos (SQLite, Firebird, PostgreSQL)

## 🚧 Estado Actual

Este proyecto está en fase de desarrollo activo. La API puede cambiar sin previo aviso.

**Versión actual:** v0.1.0-alpha

### ✅ Implementado

- [x] Sistema base de entidades (`TEntity`)
- [x] Control de estado (New, Unchanged, Modified, Deleted)
- [x] Sistema de metadata (CreatedAt, ModifiedAt, CreatedBy, ModifiedBy, Version)
- [x] Validación de entidades con mensajes tipificados
- [x] BeginLoad/EndLoad para carga sin efectos secundarios
- [x] Helpers de campo (SetFieldString, SetFieldInteger, etc.)
- [x] Serialización JSON desacoplada (principio DIP)
- [x] TEntitySerializer/TEntityDeserializer (abstracción reutilizable)
- [x] Sistema de tests unitarios con FPCUnit

### 🔨 En desarrollo

- [ ] Mapeo directo DB ↔ Entity (sin overhead JSON)
- [ ] Sistema de repositorios con soporte multi-BD
- [ ] Factory pattern para diferentes motores de BD
- [ ] Sistema de migraciones
- [ ] Documentación completa

### 📋 Roadmap

- [ ] v0.2.0: Mapeo directo DB ↔ Entity
- [ ] v0.3.0: Soporte SQLite completo
- [ ] v0.4.0: Soporte Firebird
- [ ] v0.5.0: Soporte PostgreSQL
- [ ] v0.6.0: API REST helpers
- [ ] v1.0.0: Primera versión estable

## 🏗️ Arquitectura

### Principios de Diseño

El framework está diseñado siguiendo los **principios SOLID**:

- **Single Responsibility**: Cada clase tiene una responsabilidad única
- **Open/Closed**: Extensible vía hooks virtuales
- **Liskov Substitution**: Comportamiento predecible en jerarquías
- **Interface Segregation**: APIs mínimas y específicas
- **Dependency Inversion**: Dependencia de abstracciones, no implementaciones

### Estructura de Capas

```
┌─────────────────────────────────────┐
│   UI Layer (Forms/API Endpoints)    │
├─────────────────────────────────────┤
│   Managers (Orchestration)          │
├─────────────────────────────────────┤
│   DataSources (Mapping/Binding)     │
├─────────────────────────────────────┤
│   Entities (Business Logic)         │
├─────────────────────────────────────┤
│   Repositories (Persistence)        │
├─────────────────────────────────────┤
│   DB Components (I/O)               │
└─────────────────────────────────────┘
```

### Componentes Principales

**Entidades (`TEntity`)**
- Modelo de dominio puro
- Validaciones de negocio
- Estado y metadata
- Sin dependencias de persistencia

**Serializers**
- `TEntitySerializer`: Construcción type-safe de JSON
- `TEntityDeserializer`: Lectura type-safe de JSON
- Desacoplados de las entidades (DIP)

**DataSources**
- Mapeo entre DB y entidades
- Lookup values y relaciones
- Doble vía: mapeo directo + JSON

## 🚀 Ejemplo de Uso

```pascal
uses
  entity_cl, entity_serializers;

type
  TPersona = class(TEntity)
  private
    FNombre: string;
    FEdad: Integer;
  protected
    procedure DoSerializeFields(ASerializer: TEntitySerializer); override;
    procedure DoDeserializeFields(ADeserializer: TEntityDeserializer); override;
  published
    property Nombre: string read FNombre write FNombre;
    property Edad: Integer read FEdad write FEdad;
  end;

procedure TPersona.DoSerializeFields(ASerializer: TEntitySerializer);
begin
  inherited;
  ASerializer.AddField('nombre', FNombre);
  ASerializer.AddField('edad', FEdad);
end;

procedure TPersona.DoDeserializeFields(ADeserializer: TEntityDeserializer);
begin
  inherited;
  FNombre := ADeserializer.GetString('nombre', '');
  FEdad := ADeserializer.GetInteger('edad', 0);
end;

// Uso
var
  persona: TPersona;
  json: string;
begin
  persona := TPersona.Create;
  try
    persona.BeginLoad; // Evita marcar como modificado durante carga
    persona.Nombre := 'Juan';
    persona.Edad := 30;
    persona.EndLoad;
    
    // Serializar a JSON
    json := persona.ToJSONString;
    WriteLn(json);
    
    // Validar
    if persona.Validate then
      WriteLn('Entidad válida')
    else
      WriteLn('Errores: ', persona.ValidationMessages.Count);
  finally
    persona.Free;
  end;
end;
```

## 🧪 Tests

El proyecto incluye tests unitarios con FPCUnit:

```bash
# Compilar y ejecutar tests
fpc fw_unittests.lpr
./fw_unittests
```

Tests actuales:
- Metadata (Version, CreatedBy, ModifiedBy)
- BeginLoad/EndLoad (sin efectos secundarios)
- Serialización JSON (ida y vuelta completa)

## 📦 Requisitos

- Free Pascal Compiler 3.2.0 o superior
- Lazarus 2.0.0 o superior (opcional, para IDE)
- Paquetes: fcl-json, fpcunit

## 🤝 Contribuir

Este proyecto está en desarrollo activo y acepta contribuciones. Por favor:

1. Abre un Issue para discutir cambios grandes
2. Sigue los principios SOLID establecidos
3. Añade tests para nueva funcionalidad
4. Documenta decisiones de diseño

## 📄 Licencia

MIT License - Ver archivo [LICENSE](LICENSE)

## 👤 Autor

Proyecto desarrollado como framework de uso personal y aprendizaje de buenas prácticas de diseño OOP.

## 📝 Changelog

### v0.1.0-alpha (2025-10-25)
- Implementación inicial del framework
- Sistema base de entidades con estado y metadata
- Serialización JSON desacoplada con helpers
- Tests unitarios con FPCUnit
- Documentación completa

---

⭐ Si este proyecto te resulta útil, considera darle una estrella en GitHub
