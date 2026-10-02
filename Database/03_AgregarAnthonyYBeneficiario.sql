USE MesaAyudaDb;
GO
IF COL_LENGTH(N'dbo.Tickets', N'PersonaBeneficiaria') IS NULL
    ALTER TABLE dbo.Tickets ADD PersonaBeneficiaria NVARCHAR(150) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Usuarios WHERE Correo = N'anthony@mesaayuda.local')
BEGIN
    INSERT dbo.Usuarios(NombreCompleto, Correo, PasswordHash, RolId, DepartamentoId)
    SELECT N'Anthony Gomez', N'anthony@mesaayuda.local',
        LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', 'Anthony123*'), 2)), r.RolId, d.DepartamentoId
    FROM dbo.Roles r CROSS JOIN dbo.Departamentos d
    WHERE r.Nombre = N'Administrador' AND d.Nombre = N'Sistemas';
END;
GO

CREATE OR ALTER FUNCTION dbo.fn_CalcularHashTicket
(
    @UsuarioId INT,
    @DepartamentoId INT,
    @CategoriaId INT,
    @PrioridadId INT,
    @Descripcion NVARCHAR(2000),
    @FechaCreacion DATETIME2(0),
    @EstadoId INT,
    @TecnicoId INT,
    @PersonaBeneficiaria NVARCHAR(150)
)
RETURNS CHAR(64)
AS
BEGIN
    DECLARE @Contenido NVARCHAR(MAX) = CONCAT(
        @UsuarioId, N'|', @DepartamentoId, N'|', @CategoriaId, N'|', @PrioridadId, N'|',
        @Descripcion, N'|', CONVERT(NVARCHAR(19), @FechaCreacion, 126), N'|',
        @EstadoId, N'|', COALESCE(CONVERT(NVARCHAR(20), @TecnicoId), N'NULL'),
        CASE WHEN @PersonaBeneficiaria IS NULL THEN N'' ELSE CONCAT(N'|', @PersonaBeneficiaria) END
    );

    RETURN LOWER(CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @Contenido), 2));
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_Tickets_Auditoria
ON dbo.Tickets
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UsuarioContexto INT = TRY_CONVERT(INT, SESSION_CONTEXT(N'UsuarioId'));
    DECLARE @Nota NVARCHAR(500) = TRY_CONVERT(NVARCHAR(500), SESSION_CONTEXT(N'NotaAuditoria'));

    INSERT dbo.BitacoraTickets
    (
        TicketId, UsuarioId, Operacion, Fecha, Cambios, ValoresAnteriores, ValoresNuevos
    )
    SELECT
        COALESCE(i.TicketId, d.TicketId),
        COALESCE(@UsuarioContexto, i.UsuarioSolicitanteId, d.UsuarioSolicitanteId),
        CASE
            WHEN d.TicketId IS NULL THEN N'INSERTAR'
            WHEN i.TicketId IS NULL THEN N'ELIMINAR'
            ELSE N'ACTUALIZAR'
        END,
        SYSDATETIME(),
        CASE
            WHEN d.TicketId IS NULL THEN CONCAT(N'Ticket ', i.Numero, N' registrado.')
            WHEN i.TicketId IS NULL THEN CONCAT(N'Ticket ', d.Numero, N' eliminado.')
            ELSE CONCAT(
                N'Estado ID: ', d.EstadoId, N' -> ', i.EstadoId,
                N'; Tecnico ID: ', COALESCE(CONVERT(NVARCHAR(20), d.TecnicoAsignadoId), N'Sin asignar'),
                N' -> ', COALESCE(CONVERT(NVARCHAR(20), i.TecnicoAsignadoId), N'Sin asignar'),
                CASE WHEN @Nota IS NULL THEN N'' ELSE CONCAT(N'; Nota: ', @Nota) END
            )
        END,
        CASE WHEN d.TicketId IS NULL THEN NULL ELSE
            (SELECT d.Numero, d.DepartamentoId, d.CategoriaId, d.PrioridadId, d.Descripcion, d.PersonaBeneficiaria,
                    d.EstadoId, d.TecnicoAsignadoId, d.FechaCierre, d.HashIntegridad
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END,
        CASE WHEN i.TicketId IS NULL THEN NULL ELSE
            (SELECT i.Numero, i.DepartamentoId, i.CategoriaId, i.PrioridadId, i.Descripcion, i.PersonaBeneficiaria,
                    i.EstadoId, i.TecnicoAsignadoId, i.FechaCierre, i.HashIntegridad
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) END
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.TicketId = i.TicketId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_UsuarioAutenticar
    @Correo NVARCHAR(150),
    @PasswordHash CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT u.UsuarioId, u.NombreCompleto, u.Correo, r.Nombre AS Rol
    FROM dbo.Usuarios u
    INNER JOIN dbo.Roles r ON r.RolId = u.RolId
    WHERE u.Correo = @Correo
      AND u.PasswordHash = @PasswordHash
      AND u.Activo = 1
      AND r.Activo = 1;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CatalogosListar
AS
BEGIN
    SET NOCOUNT ON;

    SELECT DepartamentoId AS Id, Nombre FROM dbo.Departamentos WHERE Activo = 1 ORDER BY Nombre;
    SELECT CategoriaId AS Id, Nombre FROM dbo.Categorias WHERE Activo = 1 ORDER BY Nombre;
    SELECT PrioridadId AS Id, Nombre FROM dbo.Prioridades WHERE Activo = 1 ORDER BY Nivel;
    SELECT EstadoId AS Id, Nombre FROM dbo.Estados WHERE Activo = 1 ORDER BY EstadoId;

    SELECT u.UsuarioId AS Id, u.NombreCompleto AS Nombre
    FROM dbo.Usuarios u
    INNER JOIN dbo.Roles r ON r.RolId = u.RolId
    WHERE u.Activo = 1 AND r.Nombre IN (N'Administrador', N'Tecnico')
    ORDER BY u.NombreCompleto;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TicketCrear
    @UsuarioId INT,
    @DepartamentoId INT,
    @CategoriaId INT,
    @PrioridadId INT,
    @Descripcion NVARCHAR(2000),
    @PersonaBeneficiaria NVARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@PersonaBeneficiaria)), N'') IS NULL
        THROW 50006, 'Indique la persona que necesita ayuda.', 1;
    SET @PersonaBeneficiaria = LTRIM(RTRIM(@PersonaBeneficiaria));

    IF LEN(LTRIM(RTRIM(@Descripcion))) < 10
        THROW 50001, 'La descripcion debe contener al menos 10 caracteres.', 1;

    DECLARE @TicketId INT = NEXT VALUE FOR dbo.SecuenciaTickets;
    DECLARE @Numero VARCHAR(20) = CONCAT('TK-', RIGHT(CONCAT('000000', @TicketId), 6));
    DECLARE @Fecha DATETIME2(0) = SYSDATETIME();
    DECLARE @EstadoId INT = (SELECT EstadoId FROM dbo.Estados WHERE Nombre = N'Abierto' AND Activo = 1);
    DECLARE @Hash CHAR(64) = dbo.fn_CalcularHashTicket(
        @UsuarioId, @DepartamentoId, @CategoriaId, @PrioridadId,
        LTRIM(RTRIM(@Descripcion)), @Fecha, @EstadoId, NULL, @PersonaBeneficiaria
    );

    EXEC sys.sp_set_session_context @key = N'UsuarioId', @value = @UsuarioId;
    EXEC sys.sp_set_session_context @key = N'NotaAuditoria', @value = N'Registro inicial del ticket.';

    INSERT dbo.Tickets
    (
        TicketId, Numero, UsuarioSolicitanteId, DepartamentoId, CategoriaId,
        PrioridadId, Descripcion, FechaCreacion, EstadoId, TecnicoAsignadoId,
        FechaCierre, HashIntegridad, PersonaBeneficiaria
    )
    VALUES
    (
        @TicketId, @Numero, @UsuarioId, @DepartamentoId, @CategoriaId,
        @PrioridadId, LTRIM(RTRIM(@Descripcion)), @Fecha, @EstadoId, NULL,
        NULL, @Hash, @PersonaBeneficiaria
    );

    SELECT @TicketId AS TicketId, @Numero AS Numero, @Hash AS HashIntegridad;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TicketsListar
    @UsuarioId INT,
    @EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        t.TicketId, t.Numero, t.FechaCreacion,
        solicitante.NombreCompleto AS Solicitante, t.PersonaBeneficiaria,
        d.Nombre AS Departamento, c.Nombre AS Categoria,
        p.PrioridadId, p.Nombre AS Prioridad,
        e.EstadoId, e.Nombre AS Estado,
        tecnico.UsuarioId AS TecnicoId, tecnico.NombreCompleto AS Tecnico,
        t.Descripcion, t.HashIntegridad,
        CONVERT(BIT, CASE WHEN t.HashIntegridad = dbo.fn_CalcularHashTicket(
            t.UsuarioSolicitanteId, t.DepartamentoId, t.CategoriaId, t.PrioridadId,
            t.Descripcion, t.FechaCreacion, t.EstadoId, t.TecnicoAsignadoId, t.PersonaBeneficiaria
        ) THEN 1 ELSE 0 END) AS HashValido
    FROM dbo.Tickets t
    INNER JOIN dbo.Usuarios solicitante ON solicitante.UsuarioId = t.UsuarioSolicitanteId
    INNER JOIN dbo.Departamentos d ON d.DepartamentoId = t.DepartamentoId
    INNER JOIN dbo.Categorias c ON c.CategoriaId = t.CategoriaId
    INNER JOIN dbo.Prioridades p ON p.PrioridadId = t.PrioridadId
    INNER JOIN dbo.Estados e ON e.EstadoId = t.EstadoId
    LEFT JOIN dbo.Usuarios tecnico ON tecnico.UsuarioId = t.TecnicoAsignadoId
    WHERE @EsAdministrador = 1 OR t.UsuarioSolicitanteId = @UsuarioId
    ORDER BY t.FechaCreacion DESC, t.TicketId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TicketsResumen
    @UsuarioId INT,
    @EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COUNT(*) AS Total,
        COALESCE(SUM(CASE WHEN p.Nombre = N'Alta' AND e.EsFinal = 0 THEN 1 ELSE 0 END), 0) AS Urgentes,
        COALESCE(SUM(CASE WHEN e.Nombre = N'En Proceso' THEN 1 ELSE 0 END), 0) AS EnProceso,
        COALESCE(SUM(CASE WHEN e.EsFinal = 1 AND CONVERT(DATE, t.FechaCierre) = CONVERT(DATE, SYSDATETIME()) THEN 1 ELSE 0 END), 0) AS ResueltosHoy
    FROM dbo.Tickets t
    INNER JOIN dbo.Prioridades p ON p.PrioridadId = t.PrioridadId
    INNER JOIN dbo.Estados e ON e.EstadoId = t.EstadoId
    WHERE @EsAdministrador = 1 OR t.UsuarioSolicitanteId = @UsuarioId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BitacoraListar
    @UsuarioId INT,
    @EsAdministrador BIT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (100)
        b.BitacoraId,
        COALESCE(t.Numero, CONCAT('Ticket ID ', b.TicketId)) AS NumeroTicket,
        COALESCE(u.NombreCompleto, N'Sistema') AS Usuario,
        b.Operacion,
        b.Fecha,
        b.Cambios
    FROM dbo.BitacoraTickets b
    LEFT JOIN dbo.Tickets t ON t.TicketId = b.TicketId
    LEFT JOIN dbo.Usuarios u ON u.UsuarioId = b.UsuarioId
    WHERE @EsAdministrador = 1 OR t.UsuarioSolicitanteId = @UsuarioId
    ORDER BY b.Fecha DESC, b.BitacoraId DESC;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_TicketActualizar
    @TicketId INT,
    @TecnicoId INT = NULL,
    @EstadoId INT,
    @Nota NVARCHAR(500) = NULL,
    @UsuarioAccionId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Usuarios u
        INNER JOIN dbo.Roles r ON r.RolId = u.RolId
        WHERE u.UsuarioId = @UsuarioAccionId
          AND u.Activo = 1
          AND r.Nombre IN (N'Administrador', N'Tecnico')
    )
        THROW 50002, 'El usuario no tiene permisos para administrar tickets.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Tickets WHERE TicketId = @TicketId)
        THROW 50003, 'El ticket indicado no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Estados WHERE EstadoId = @EstadoId AND Activo = 1)
        THROW 50004, 'El estado indicado no es valido.', 1;

    IF @TecnicoId IS NOT NULL AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.Usuarios u
        INNER JOIN dbo.Roles r ON r.RolId = u.RolId
        WHERE u.UsuarioId = @TecnicoId AND u.Activo = 1
          AND r.Nombre IN (N'Administrador', N'Tecnico')
    )
        THROW 50005, 'El tecnico indicado no es valido.', 1;

    DECLARE @EsFinal BIT = (SELECT EsFinal FROM dbo.Estados WHERE EstadoId = @EstadoId);
    DECLARE @Hash CHAR(64);

    SELECT @Hash = dbo.fn_CalcularHashTicket(
        UsuarioSolicitanteId, DepartamentoId, CategoriaId, PrioridadId,
        Descripcion, FechaCreacion, @EstadoId, @TecnicoId, PersonaBeneficiaria
    )
    FROM dbo.Tickets
    WHERE TicketId = @TicketId;

    EXEC sys.sp_set_session_context @key = N'UsuarioId', @value = @UsuarioAccionId;
    EXEC sys.sp_set_session_context @key = N'NotaAuditoria', @value = @Nota;

    UPDATE dbo.Tickets
    SET TecnicoAsignadoId = @TecnicoId,
        EstadoId = @EstadoId,
        FechaCierre = CASE WHEN @EsFinal = 1 THEN COALESCE(FechaCierre, SYSDATETIME()) ELSE NULL END,
        HashIntegridad = @Hash
    WHERE TicketId = @TicketId;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_EvidenciaCrear
    @TicketId INT,
    @UsuarioId INT,
    @NombreOriginal NVARCHAR(255),
    @RutaRelativa NVARCHAR(500),
    @TipoContenido NVARCHAR(100),
    @TamanioBytes BIGINT,
    @HashArchivo CHAR(64)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Tickets t
        INNER JOIN dbo.Usuarios u ON u.UsuarioId = @UsuarioId AND u.Activo = 1
        INNER JOIN dbo.Roles r ON r.RolId = u.RolId
        WHERE t.TicketId = @TicketId
          AND (t.UsuarioSolicitanteId = @UsuarioId OR r.Nombre IN (N'Administrador', N'Tecnico'))
    )
        THROW 50006, 'No tiene permisos para adjuntar evidencia a este ticket.', 1;

    INSERT dbo.Evidencias
    (
        TicketId, NombreOriginal, RutaRelativa, TipoContenido,
        TamanioBytes, HashArchivo, UsuarioId
    )
    VALUES
    (
        @TicketId, @NombreOriginal, @RutaRelativa, @TipoContenido,
        @TamanioBytes, @HashArchivo, @UsuarioId
    );
END;
GO

SELECT N'Anthony y persona beneficiaria configurados.' AS Resultado;
GO
