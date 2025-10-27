# JS-Framework - Framework de Entidades para Free Pascal/Lazarus

⚠️ **Estado: Alpha / Desarrollo Activo**

La idea es desarrollar un framework para desarrollo de aplicaciones desktop y web en Free Pascal/Lazarus. El proyecto es la evolución de otro anterior.
A medida que el proyecto se vaya estabilizando, pretendo publicar en un blog una descripción detallada tanto de su funcionamiento como de su arquitectura.
En breve incluiré también una aplicación de ejemplo para mostrar las funcionalidades del mismo.

**JS-Framework** es desarrollado por **Janasoft**.

## 🎯 Objetivo
Mi objetivo básico es llevar a la práctica mis conocimientos siguiendo los principios SOLID y las buenas prácticas de diseño. Evidentemente, no creo que esté en mi maño diseñar el mejor y más potente framework, ni mucho menos competir con otros ya maduros y estables. Pero todo eso no quiere decir que no pretenda conseguir un framework perfectamente utilizable tanto en aplicaciones de escritorio (Lazarus/LCL) como en entornos web.

## 🚧 Estado Actual
Este framework es la evolución de otro mucho más limitado en cuanto a funcionalidad ya que solo estaba pensado para aplicaciones de escritorio. Aunque adolecía de algunos defectos, funcionaba correctamente, por lo que ya parto de una base sólida para el desarrollo actual.
En todo caso este proyecto está en fase de desarrollo activo, por lo que la API puede cambiar sin previo aviso.
A medida que se desarrollen las distintas funcionalidades se irán creando las correspondientes pruebas unitarias

**Versión actual:** v0.1.0-alpha

### � En desarrollo

Hay muchas funcionalidades pendientes de desarrollar por lo que, en este momento, no tiene demasiado sentido hacer una lista


## 🏗️ Arquitectura

### Principios de Diseño

El framework está diseñado intentando aplicar los **principios SOLID**. No creo necesario explicar aquí esos principios ya que son del dominio público. Simplemente reflejo las premisas básicas:

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
│   Managers (Orquestador)            │
├─────────────────────────────────────┤
│   DataSources (Mapeo/Enlazado)      │
├─────────────────────────────────────┤
│   Entities                          │
├─────────────────────────────────────┤
│   Repositories (Persistencia)       │
├─────────────────────────────────────┤
│   DB Components (I/O)               │
└─────────────────────────────────────┘
```

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

Proyecto desarrollado por Janasoft como framework de uso personal y aprendizaje de buenas prácticas de diseño OOP.

---

⭐ Si este proyecto te resulta útil, considera darle una estrella en GitHub
