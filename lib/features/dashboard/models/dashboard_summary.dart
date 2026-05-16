class DashboardSummary {
  const DashboardSummary({
    this.totalSpent = 0,
    this.needToPay = 0,
    this.willReceive = 0,
    this.monthYouPaid = 0,
    this.monthNeedToPay = 0,
    this.monthTotalSpent = 0,
    this.monthWillReceive = 0,
  });

  final double totalSpent;
  final double needToPay;
  final double willReceive;
  final double monthYouPaid;
  final double monthNeedToPay;
  final double monthTotalSpent;
  final double monthWillReceive;
}
