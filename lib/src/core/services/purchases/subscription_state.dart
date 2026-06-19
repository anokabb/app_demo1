part of 'subscription_cubit.dart';

class SubscriptionState {
  final bool isLoading;
  final bool isSubscriber;
  final CustomerInfo? customerInfo;
  final String? error;
  final int freeLimit;

  const SubscriptionState({
    this.isLoading = false,
    this.isSubscriber = false,
    this.customerInfo,
    this.error,
    this.freeLimit = 0,
  });

  const SubscriptionState.initial() : this();

  SubscriptionState copyWith({
    bool? isLoading,
    bool? isSubscriber,
    CustomerInfo? customerInfo,
    String? error,
    int? freeLimit,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isSubscriber: isSubscriber ?? this.isSubscriber,
      customerInfo: customerInfo ?? this.customerInfo,
      error: error ?? this.error,
      freeLimit: freeLimit ?? this.freeLimit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionState &&
        other.isLoading == isLoading &&
        other.isSubscriber == isSubscriber &&
        other.customerInfo == customerInfo &&
        other.error == error &&
        other.freeLimit == freeLimit;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^ isSubscriber.hashCode ^ customerInfo.hashCode ^ error.hashCode ^ freeLimit.hashCode;
  }

  @override
  String toString() {
    return 'SubscriptionState(isLoading: $isLoading, isSubscriber: $isSubscriber, customerInfo: $customerInfo, error: $error, freeLimit: $freeLimit)';
  }
}
