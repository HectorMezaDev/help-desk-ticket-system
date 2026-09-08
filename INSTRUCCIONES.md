# Como instalar y ejecutar MesaAyuda

## Requisitos

- Visual Studio con la carga de trabajo **Desarrollo de ASP.NET y web**.
- .NET Framework 4.8.
- SQL Server y SQL Server Management Studio.
- Instancia configurada para este equipo: `.\MSSQLSERVER2025`.

## 1. Crear la base de datos

1. Abra SQL Server Management Studio.
2. En **Nombre del servidor** escriba `.\MSSQLSERVER2025`.
3. Use **Autenticacion de Windows** y conectese.
4. Abra `Database\01_CrearMesaAyudaDb.sql`.
5. Presione **Ejecutar** o `F5`.
6. Confirme que aparezca el mensaje `MesaAyudaDb instalada correctamente.`.
7. Abra `Database\02_VerificarInstalacion.sql` y ejecutelo para revisar los objetos creados.

El instalador es repetible: puede ejecutarlo nuevamente sin eliminar la informacion existente.

## 2. Ejecutar la aplicacion

1. Abra `MesaAyuda.sln` en Visual Studio.
2. En el Explorador de soluciones, haga clic derecho en `MesaAyuda.Frontend`.
3. Seleccione **Establecer como proyecto de inicio**.
4. Seleccione **IIS Express** en la barra superior.
5. Presione `F5` o `Ctrl+F5`.

La aplicacion abre `Login.aspx`. Use uno de estos usuarios:

| Rol | Correo | Contrasena |
| --- | --- | --- |
| Administrador | `admin@mesaayuda.local` | `Admin123*` |
| Tecnico | `tecnico@mesaayuda.local` | `Tecnico123*` |
| Empleado | `empleado@mesaayuda.local` | `Empleado123*` |

## Configuracion de SQL Server

La conexion esta en `MesaAyuda.Frontend\Web.config`:

```xml
Data Source=.\MSSQLSERVER2025;Initial Catalog=MesaAyudaDb;Integrated Security=True;TrustServerCertificate=True
```

Si se ejecuta en otra computadora, sustituya unicamente `Data Source` por el nombre de su instancia.

## Comprobacion funcional

1. Inicie sesion como administrador.
2. Registre un ticket con una descripcion de al menos 10 caracteres.
3. Adjunte opcionalmente un archivo PNG, JPG o PDF menor o igual a 5 MB.
4. Abra **Panel Administrativo TI** y seleccione **Administrar**.
5. Asigne un tecnico, cambie el estado y escriba una nota.
6. Abra **Mis Tickets (Historial)** y confirme que aparezca la modificacion.

El icono de integridad debe mostrar **Valido**. El trigger `tr_Tickets_Auditoria` crea la bitacora automaticamente.
