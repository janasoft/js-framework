# Contribuir a JS-Framework

¡Gracias por tu interés en contribuir! Este documento proporciona guías para contribuir al proyecto.

## 🎯 Filosofía del Proyecto

Este framework se desarrolla siguiendo:
- **Principios SOLID** estrictamente
- **Código limpio** y bien documentado
- **Tests unitarios** para toda funcionalidad nueva
- **Compatibilidad hacia atrás** cuando sea posible
- **Simplicidad** sin sacrificar flexibilidad

## 🤔 ¿Cómo puedo contribuir?

### Reportar Bugs

Si encuentras un bug:

1. **Verifica** que no exista ya un issue similar
2. **Crea un issue** con:
   - Descripción clara del problema
   - Pasos para reproducirlo
   - Comportamiento esperado vs actual
   - Versión de FPC/Lazarus
   - Sistema operativo

**Plantilla de Bug Report:**
```markdown
**Descripción del bug**
Descripción clara y concisa del problema.

**Para reproducir**
1. Crear una instancia de '...'
2. Llamar al método '...'
3. Observar error

**Comportamiento esperado**
Lo que debería suceder.

**Entorno**
- OS: [Windows/Linux/macOS]
- FPC: [versión]
- Lazarus: [versión]
```

### Sugerir Mejoras

Para sugerir nuevas características:

1. **Abre un issue** con etiqueta `enhancement`
2. **Describe** el caso de uso
3. **Explica** cómo encaja con la filosofía del proyecto
4. **Considera** alternativas y trade-offs

### Pull Requests

#### Antes de empezar

1. **Discute** cambios grandes en un issue primero
2. **Lee** la documentación de arquitectura
3. **Familiarízate** con los principios SOLID aplicados

#### Proceso

1. **Fork** el repositorio
2. **Crea** una rama desde `develop`:
   ```bash
   git checkout develop
   git checkout -b feature/mi-caracteristica
   ```
3. **Implementa** tu cambio siguiendo las guías de estilo
4. **Añade tests** para tu funcionalidad
5. **Documenta** tu código
6. **Commit** con mensajes descriptivos
7. **Push** a tu fork
8. **Abre** un Pull Request contra `develop`

#### Estructura de commits

Usa commits descriptivos:
```
tipo(ámbito): descripción breve

Descripción más detallada si es necesaria.

- Cambio específico 1
- Cambio específico 2
```

Tipos:
- `feat`: Nueva característica
- `fix`: Corrección de bug
- `refactor`: Refactorización sin cambio de funcionalidad
- `docs`: Solo documentación
- `test`: Añadir o modificar tests
- `style`: Cambios de formato (sin afectar código)
- `perf`: Mejoras de rendimiento

Ejemplo:
```
feat(entity): añadir soporte para DateTime en serialización

Implementa helpers en TEntitySerializer/Deserializer para
manejar campos de tipo TDateTime.

- AddField sobrecargado para TDateTime
- GetDateTime con formato ISO8601
- Tests para serialización de fechas
```

## 📐 Guías de Estilo

### Código Pascal

**Nomenclatura:**
```pascal
// Clases: TPascalCase
type
  TMyEntity = class(TEntity)
  
// Interfaces: IPascalCase
type
  IRepository = interface
  
// Variables privadas: FPascalCase
private
  FMyField: string;
  
// Parámetros: APascalCase
procedure DoSomething(AValue: string);

// Variables locales: camelCase o lowercase
var
  myVar: Integer;
  i: Integer;
```

**Principios:**
```pascal
// SRP - Una clase, una responsabilidad
type
  TEntitySerializer = class  // Solo serializa
  TEntityValidator = class    // Solo valida
  
// OCP - Extensible, no modificable
protected
  procedure DoSerializeFields(ASerializer: TEntitySerializer); virtual;
  
// DIP - Depender de abstracciones
uses
  entity_serializers;  // Abstracción
  // NO: fpjson;       // Implementación concreta
```

**Documentación:**
```pascal
{ TEntitySerializer - Helper para serialización
  
  Responsabilidades:
  - Construir JSON de forma type-safe
  - Abstraer fpjson de las entidades
  
  Principios SOLID:
  - SRP: Solo se encarga de serializar
  - DIP: Entidades dependen de este helper, no de fpjson
  
  Uso:
    serializer := TEntitySerializer.Create;
    try
      serializer.AddField('name', 'Juan');
      json := serializer.GetJSONString;
    finally
      serializer.Free;
    end;
}
```

### Tests

**Estructura:**
```pascal
// Una aserción por test
procedure TMyTests.TestFieldSerialization;
begin
  FEntity.Name := 'Test';
  AssertEquals('Name debe serializarse', 'Test', 
    DeserializeField(Serialize(FEntity), 'name'));
end;

// Setup/TearDown para preparar contexto
procedure TMyTestCase.SetUp;
begin
  inherited;
  FEntity := TMyEntity.Create;
  FEntity.UpdateMetadata('TestUser');
end;
```

**Nombres descriptivos:**
```pascal
// ✅ Bueno
procedure TestVersionIncrementOnModification;
procedure TestBeginLoadPreventsStateChange;

// ❌ Malo
procedure Test1;
procedure TestEntity;
```

## 🏗️ Arquitectura

### Capas y Responsabilidades

```
Entity Layer (entity_cl.pas)
├─ Lógica de negocio pura
├─ Sin dependencias de UI o BD
└─ Hooks virtuales para extensión

Serialization Layer (entity_serializers.pas)
├─ Abstracción de formato (JSON)
├─ Type-safe API
└─ Reutilizable

DataSource Layer (baseds_cl.pas, ciudades_ds.pas)
├─ Mapeo DB ↔ Entity
├─ Lookups y relaciones
└─ Orquestación

Persistence Layer (basedb_cl.pas)
├─ Acceso físico a BD
├─ SQL y transacciones
└─ Sin lógica de negocio
```

### Decisiones de Diseño Clave

1. **Version**: Se incrementa en repositorio, no en entidad
2. **BeginLoad/EndLoad**: Suspende efectos secundarios durante carga
3. **Serialización**: Opcional, no afecta persistencia tradicional
4. **Metadata**: Actualización explícita vía métodos dedicados

## ✅ Checklist para PR

Antes de enviar tu PR:

- [ ] El código compila sin warnings
- [ ] Todos los tests existentes pasan
- [ ] Añadidos tests para nueva funcionalidad
- [ ] Código documentado (comentarios en partes complejas)
- [ ] Sigue principios SOLID
- [ ] Sin dependencias innecesarias
- [ ] README actualizado si es necesario
- [ ] CHANGELOG.md actualizado
- [ ] Commits con mensajes descriptivos

## 🤝 Código de Conducta

- Sé respetuoso y constructivo
- Acepta críticas de forma positiva
- Enfócate en el código, no en las personas
- Ayuda a otros a mejorar

## 📞 ¿Preguntas?

- Abre un issue con la etiqueta `question`
- Revisa issues existentes primero

---

¡Gracias por contribuir! 🎉
