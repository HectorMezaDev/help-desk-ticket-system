namespace MesaAyuda.Backend.Dtos
{
    public class TicketDto
    {
        public int TicketId { get; set; }
        public string Numero { get; set; }
        public string Fecha { get; set; }
        public string Solicitante { get; set; }
        public string Departamento { get; set; }
        public string Categoria { get; set; }
        public int PrioridadId { get; set; }
        public string Prioridad { get; set; }
        public int EstadoId { get; set; }
        public string Estado { get; set; }
        public int? TecnicoId { get; set; }
        public string Tecnico { get; set; }
        public string PersonaBeneficiaria { get; set; }
        public string Descripcion { get; set; }
        public string HashIntegridad { get; set; }
        public bool HashValido { get; set; }
    }
}
