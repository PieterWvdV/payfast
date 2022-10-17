class SubscriptionPayment {
  String amount;
  String item_name;
  late String subscriptions_type;
  String billing_date;
  String recurring_amount;
  String frequency;
  String cycles;
  String? name_first;
  String? name_last;
  String? email_address;

  SubscriptionPayment({
    required this.amount,
    required this.item_name,
    required this.billing_date,
    required this.recurring_amount,
    required this.frequency,
    required this.cycles,
    this.name_first,
    this.name_last,
    this.email_address
  }) {
    subscriptions_type = '1';
  }

  void setupSubscriptionPayment(String test) {}
}
