const summaryCards = [
  { label: "Total Requests", value: "0" },
  { label: "Draft", value: "0" },
  { label: "Submitted", value: "0" },
  { label: "In Review", value: "0" },
  { label: "Approved", value: "0" },
  { label: "Rejected", value: "0" },
];

export function DashboardPage() {
  return (
    <section className="page">
      <header className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p>Summary metrics for the current workflow state.</p>
        </div>
      </header>

      <div className="card-grid">
        {summaryCards.map((card) => (
          <article key={card.label} className="card stat-card">
            <span className="stat-card__label">{card.label}</span>
            <strong className="stat-card__value">{card.value}</strong>
          </article>
        ))}
      </div>
    </section>
  );
}
