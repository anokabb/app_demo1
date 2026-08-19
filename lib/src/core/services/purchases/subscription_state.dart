part of 'subscription_cubit.dart';

/// Default value for [SubscriptionState.copyWith]'s nullable params so an
/// omitted argument ("keep current value") can be told apart from an explicit
/// `null` ("clear this field"). Without it `error: null` was a silent no-op and
/// the error could never be cleared once set.
const _unspecified = Object();

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

  /// Nullable fields ([error], [customerInfo]) accept an explicit `null` to
  /// clear them — omit the argument entirely to keep the current value.
  SubscriptionState copyWith({
    bool? isLoading,
    bool? isSubscriber,
    Object? customerInfo = _unspecified,
    Object? error = _unspecified,
    int? freeLimit,
  }) {
    return SubscriptionState(
      isLoading: isLoading ?? this.isLoading,
      isSubscriber: isSubscriber ?? this.isSubscriber,
      customerInfo: identical(customerInfo, _unspecified) ? this.customerInfo : customerInfo as CustomerInfo?,
      error: identical(error, _unspecified) ? this.error : error as String?,
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
