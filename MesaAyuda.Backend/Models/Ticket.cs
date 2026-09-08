using System;

namespace MesaAyuda.Backend.Models
{
    public class Ticket
    {
        public int Id { get; set; }
        public string Numero { get; set; }
        public int UsuarioSolicitanteId { get; set; }
        public int DepartamentoId { get; set; }
        public int CategoriaId { get; set; }
        public int PrioridadId { get; set; }
        public string Descripcion { get; set; }
        public DateTime FechaCreacion { get; set; }
        public int EstadoId { get; set; }
        public int? TecnicoAsignadoId { get; set; }
        public string HashIntegridad { get; set; }
    }
}
