using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using MesaAyuda.Backend.Data;
using MesaAyuda.Backend.Dtos;

namespace MesaAyuda.Backend.Services
{
    public class TicketService
    {
        public List<TicketDto> Listar(int usuarioId, bool esAdministrador)
        {
            List<TicketDto> tickets = new List<TicketDto>();

            using (SqlConnection conexion = Conexion.Crear())
            using (SqlCommand comando = new SqlCommand("dbo.sp_TicketsListar", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;
                comando.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
                comando.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = esAdministrador;
                conexion.Open();

                using (SqlDataReader lector = comando.ExecuteReader())
                {
                    while (lector.Read())
                    {
                        tickets.Add(MapearTicket(lector));
                    }
                }
            }

            return tickets;
        }

        public ResumenDto ObtenerResumen(int usuarioId, bool esAdministrador)
        {
            using (SqlConnection conexion = Conexion.Crear())
            using (SqlCommand comando = new SqlCommand("dbo.sp_TicketsResumen", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;
                comando.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
                comando.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = esAdministrador;
                conexion.Open();

                using (SqlDataReader lector = comando.ExecuteReader())
                {
                    if (!lector.Read())
                    {
                        return new ResumenDto();
                    }

                    return new ResumenDto
                    {
                        Total = Convert.ToInt32(lector["Total"]),
                        Urgentes = Convert.ToInt32(lector["Urgentes"]),
                        EnProceso = Convert.ToInt32(lector["EnProceso"]),
                        ResueltosHoy = Convert.ToInt32(lector["ResueltosHoy"])
                    };
                }
            }
        }

        public List<HistorialDto> ListarHistorial(int usuarioId, bool esAdministrador)
        {
            List<HistorialDto> historial = new List<HistorialDto>();

            using (SqlConnection conexion = Conexion.Crear())
            using (SqlCommand comando = new SqlCommand("dbo.sp_BitacoraListar", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;
                comando.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = usuarioId;
                comando.Parameters.Add("@EsAdministrador", SqlDbType.Bit).Value = esAdministrador;
                conexion.Open();

                using (SqlDataReader lector = comando.ExecuteReader())
                {
                    while (lector.Read())
                    {
                        historial.Add(new HistorialDto
                        {
                            BitacoraId = Convert.ToInt64(lector["BitacoraId"]),
                            NumeroTicket = Convert.ToString(lector["NumeroTicket"]),
                            Usuario = Convert.ToString(lector["Usuario"]),
                            Operacion = Convert.ToString(lector["Operacion"]),
                            Fecha = Convert.ToDateTime(lector["Fecha"]).ToString("dd/MM/yyyy HH:mm"),
                            Cambios = Convert.ToString(lector["Cambios"])
                        });
                    }
                }
            }

            return historial;
        }

        public TicketCreadoDto Crear(TicketCrearDto ticket)
        {
            if (ticket == null || ticket.UsuarioId <= 0 || ticket.DepartamentoId <= 0 ||
                ticket.CategoriaId <= 0 || ticket.PrioridadId <= 0 || string.IsNullOrWhiteSpace(ticket.Descripcion))
            {
                throw new ArgumentException("Los datos del ticket estan incompletos.");
            }

            using (SqlConnection conexion = Conexion.Crear())
            using (SqlCommand comando = new SqlCommand("dbo.sp_TicketCrear", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;
                comando.Parameters.Add("@UsuarioId", SqlDbType.Int).Value = ticket.UsuarioId;
                comando.Parameters.Add("@DepartamentoId", SqlDbType.Int).Value = ticket.DepartamentoId;
                comando.Parameters.Add("@CategoriaId", SqlDbType.Int).Value = ticket.CategoriaId;
                comando.Parameters.Add("@PrioridadId", SqlDbType.Int).Value = ticket.PrioridadId;
                comando.Parameters.Add("@Descripcion", SqlDbType.NVarChar, 2000).Value = ticket.Descripcion.Trim();
                conexion.Open();

                using (SqlDataReader lector = comando.ExecuteReader())
                {
                    lector.Read();
                    return new TicketCreadoDto
                    {
                        TicketId = Convert.ToInt32(lector["TicketId"]),
                        Numero = Convert.ToString(lector["Numero"]),
                        HashIntegridad = Convert.ToString(lector["HashIntegridad"])
                    };
                }
            }
        }

        public void Actualizar(TicketActualizarDto ticket)
        {
            if (ticket == null || ticket.TicketId <= 0 || ticket.EstadoId <= 0 || ticket.UsuarioAccionId <= 0)
            {
                throw new ArgumentException("Los datos de actualizacion estan incompletos.");
            }

            using (SqlConnection conexion = Conexion.Crear())
            using (SqlCommand comando = new SqlCommand("dbo.sp_TicketActualizar", conexion))
            {
                comando.CommandType = CommandType.StoredProcedure;
                comando.Parameters.Add("@TicketId", SqlDbType.Int).Value = ticket.TicketId;
                comando.Parameters.Add("@TecnicoId", SqlDbType.Int).Value = (object)ticket.TecnicoId ?? DBNull.Value;
                comando.Parameters.Add("@EstadoId", SqlDbType.Int).Value = ticket.EstadoId;
                comando.Parameters.Add("@Nota", SqlDbType.NVarChar, 500).Value = string.IsNullOrWhiteSpace(ticket.Nota) ? (object)DBNull.Value : ticket.Nota.Trim();
                comando.Parameters.Add("@UsuarioAccionId", SqlDbType.Int).Value = ticket.UsuarioAccionId;
                conexion.Open();
                comando.ExecuteNonQuery();
            }
        }

        private static TicketDto MapearTicket(SqlDataReader lector)
        {
            return new TicketDto
            {
                TicketId = Convert.ToInt32(lector["TicketId"]),
                Numero = Convert.ToString(lector["Numero"]),
                Fecha = Convert.ToDateTime(lector["FechaCreacion"]).ToString("dd/MM/yyyy HH:mm"),
                Solicitante = Convert.ToString(lector["Solicitante"]),
                Departamento = Convert.ToString(lector["Departamento"]),
                Categoria = Convert.ToString(lector["Categoria"]),
                PrioridadId = Convert.ToInt32(lector["PrioridadId"]),
                Prioridad = Convert.ToString(lector["Prioridad"]),
                EstadoId = Convert.ToInt32(lector["EstadoId"]),
                Estado = Convert.ToString(lector["Estado"]),
                TecnicoId = lector["TecnicoId"] == DBNull.Value ? (int?)null : Convert.ToInt32(lector["TecnicoId"]),
                Tecnico = lector["Tecnico"] == DBNull.Value ? string.Empty : Convert.ToString(lector["Tecnico"]),
                Descripcion = Convert.ToString(lector["Descripcion"]),
                HashIntegridad = Convert.ToString(lector["HashIntegridad"]),
                HashValido = Convert.ToBoolean(lector["HashValido"])
            };
        }
    }
}
