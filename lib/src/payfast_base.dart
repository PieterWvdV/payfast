import 'dart:convert';

import 'package:payfast/src/billing_types/recurring_billing_types.dart/subscription_editing.dart';
import 'package:payfast/src/billing_types/recurring_billing_types.dart/subscription_payment.dart';
import 'package:payfast/src/billing_types/recurring_billing_types.dart/tokenization_billing.dart';
import 'package:payfast/src/merchant_details.dart';
import 'package:payfast/src/services/signature_service.dart';

import 'billing_types/recurring_billing.dart';
import 'billing_types/simple_billing.dart';
import 'enums.dart';

class Payfast {
  String passphrase;
  PaymentType paymentType;
  bool production;

  RecurringBilling? recurringBilling;
  SimpleBilling? simpleBilling;
  // TokenizationBilling? tokenizationBilling;
  MerchantDetails merchantDetails;

  Payfast({
    required this.passphrase,
    required this.paymentType,
    required this.production,
    required this.merchantDetails,
  });

  String generatePaymentURL() {
    Map<String, dynamic> queryParameters = {};
    //Simple Payment
    if (paymentType == PaymentType.SimplePayment) {
      Map<String, dynamic> simpleQueryParameters = {
        ...merchantDetails.toMap(),
        'amount': simpleBilling?.amount,
        'item_name': simpleBilling?.item_name,
      };

      queryParameters = simpleQueryParameters;
    }
    //Recurring Billing
    else if (paymentType == PaymentType.RecurringBilling) {
      //Subscription
      if (recurringBilling?.recurringPaymentType ==
          RecurringPaymentType.subscription) {
        Map<String, dynamic> recurringSubscriptionQueryParameters = {
          ...merchantDetails.toMap(),
          'name_first': recurringBilling?.subscriptionPayment?.name_first,
          'name_last': recurringBilling?.subscriptionPayment?.name_last,
          'email_address': recurringBilling?.subscriptionPayment?.email_address,
          'amount': recurringBilling?.subscriptionPayment?.amount,
          'item_name': recurringBilling?.subscriptionPayment?.item_name,
          'subscription_type':
              recurringBilling?.subscriptionPayment?.subscriptions_type,
          'billing_date': recurringBilling?.subscriptionPayment?.billing_date,
          'recurring_amount':
              recurringBilling?.subscriptionPayment?.recurring_amount,
          'frequency': recurringBilling?.subscriptionPayment?.frequency,
          'cycles': recurringBilling?.subscriptionPayment?.cycles,
        };

        queryParameters = recurringSubscriptionQueryParameters;
      }
      //Tokenization
      else if (recurringBilling?.recurringPaymentType ==
          RecurringPaymentType.tokenization) {
        Map<String, dynamic> recurringTokenizationQueryParameters = {
          ...merchantDetails.toMap(),
          'amount': '250',
          'item_name': 'Netflix',
          'subscription_type':
              recurringBilling?.tokenizationBilling?.subscription_type,
        };

        queryParameters = recurringTokenizationQueryParameters;
      } else {
        throw Exception("Payment type not selected");
      }
    }

    return Uri.decodeComponent(
      Uri(
        scheme: 'https',
        host: '${production ? 'payfast' : 'sandbox.payfast'}.co.za',
        path: '/eng/process',
        queryParameters: {
          ...queryParameters,
          'signature': SignatureService.createSignature(
            queryParameters,
            passphrase,
          ),
        },
      ).toString(),
    );
  }

  void createSimplePayment({
    required String amount,
    required String itemName,
  }) {
    simpleBilling = SimpleBilling(
      amount: amount,
      item_name: itemName,
    );
  }

  void setRecurringBillingType(RecurringPaymentType recurringPaymentType) {
    recurringBilling =
        RecurringBilling(recurringPaymentType: recurringPaymentType);
  }

  void setupRecurringBillingSubscription({
    required int amount,
    required String itemName,
    required String billingDate,
    required int cycles,
    required FrequencyCyclePeriod cyclePeriod,
    required int recurringAmount,
    String? firstName,
    String? lastName,
    String? emailAddress,
  }) {
    recurringBilling!.subscriptionPayment = SubscriptionPayment(
      amount: amount.toString(),
      item_name: itemName,
      billing_date: billingDate,
      recurring_amount: recurringAmount.toString(),
      frequency: (cyclePeriod.index + 3).toString(),
      cycles: cycles.toString(),
      name_first: firstName,
      name_last: lastName,
      email_address: emailAddress
    );
  }

  void setupRecurringBillingTokenization([
    int? amount,
    String? itemName,
  ]) {
    recurringBilling!.tokenizationBilling = TokenizationBilling(
      amount.toString(),
      itemName,
    );
  }

  void chargeTokenization() {
    Map<String, dynamic> recurringTokenizationQueryParameters = {
      'token': '3ee21522-7cc9-464d-837a-3e791c5a6f1d',
      'merchant-id': '10026561',
      'version': 'v1',
      'timestamp': '2022-07-25',
      'amount': '444',
      'item_name': 'Netflix',
    };

    Map<String, dynamic> signatureEntry = {
      'signature': SignatureService.createSignature(
          recurringTokenizationQueryParameters, 'JoshuaMunstermann'),
    };

    recurringTokenizationQueryParameters.addEntries(signatureEntry.entries);

    print(recurringTokenizationQueryParameters);
  }

  /**
   * This can only be used on the production server
   */
  SubscriptionEditing generateSubscriptionCancelInfo(String subscriptionToken) {
    Map<String, dynamic> headers = {
      "merchant-id": merchantDetails.merchantId,
      "version": "v1",
      "timestamp": DateTime.now().toString()
    };

    return SubscriptionEditing(
        url: Uri.decodeComponent(
          Uri(
            scheme: 'https',
            host: 'api.payfast.co.za',
            path: '/subscriptions/$subscriptionToken/cancel',
          ).toString(),
        ),
        headers: {
          ...headers,
          'signature': SignatureService.createSignature(
            headers,
            passphrase,
          ),
        });
  }
}
