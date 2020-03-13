import 'dart:async';

import 'package:boily/boily.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

import 'boily_error_store.dart';

part 'boily_store.g.dart';

enum StoreStatus {
  // to be safe in states
  none,
  // to show full screen loading
  fetching,
  // to show overlay loading
  loading,
  // to handle success response from API
  success,
  // to handle APIs errors and show full screen error
  error,
  // to handle errors and show overlay error (snack)
  warn,
  // to show given empty widget
  empty,
}

class BoilyStore = _BoilyStore with _$BoilyStore;

abstract class _BoilyStore with Store {
  @observable
  StoreStatus _status = StoreStatus.none;

  @computed
  StoreStatus get status => _status;

  @computed
  bool get isLoading => status == StoreStatus.loading;

  @computed
  bool get isFetching => status == StoreStatus.fetching;

  @computed
  bool get isSuccess => status == StoreStatus.success;

  @computed
  bool get isError => status == StoreStatus.error;

  @computed
  bool get isWarn => status == StoreStatus.warn;

  @computed
  bool get isEmpty => status == StoreStatus.empty;

  @observable
  bool isDisconnected = false;

  @observable
  String successSnack;

  @observable
  String infoSnack;

  final BoilyErrorStore errorStore = BoilyErrorStore();
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectionSubscription;

  _BoilyStore() {
    _connectivity
        .checkConnectivity()
        .then((value) => isDisconnected = value == ConnectivityResult.none);
    _connectionSubscription =
        _connectivity.onConnectivityChanged.listen((event) {
          handleConnection(event);
    });
  }

  @action
  void handleConnection(ConnectivityResult event){
    print('connection: $event');
    isDisconnected = event == ConnectivityResult.none;
    if (isDisconnected) {
      onWarn(warn: Boily.disconnectMessage ?? 'Internet Connection Lost...');
      if (isFetching) {
        onError(
            error: Boily.disconnectMessage ?? 'Internet Connection Lost...');
//          errorStore.errorMessage =
//              Boily.disconnectMessage ?? 'Internet Connection Lost...';
      }
    }
  }

  void dispose() {
    print('base store dispose');
    _connectionSubscription.cancel();
  }

  @action
  void resetStore() {
    print('store reset');
    setStatus(StoreStatus.none);
    errorStore.resetSnackError();
  }

  @protected
  @action
  void onFetch({Function doMore}) {
    print('store onFetch');
    if (isDisconnected) {
      errorStore.errorMessage =
          Boily.disconnectMessage ?? 'Internet Connection Lost...';
    } else {
      setStatus(StoreStatus.fetching);
    }
    if (doMore != null) doMore();
  }

  @protected
  @action
  void onRequest({Function doMore}) {
    print('store onRequest');
    if (isDisconnected) {
      errorStore.snackError =
          Boily.disconnectMessage ?? 'Internet Connection Lost...';
    } else {
      setStatus(StoreStatus.loading);
    }
    if (doMore != null) doMore();
  }

  @protected
  @action
  void onSuccess({Function doMore}) {
    print('store onSuccess');
    setStatus(StoreStatus.success);
    errorStore.errorMessage = null;
    if (doMore != null) doMore();
  }

  @protected
  @action
  void onError({@required String error, Function doMore}) {
    print('store onError, error: $error');
    setStatus(StoreStatus.error);
    errorStore.errorMessage = (error != null && error.isNotEmpty)
        ? error
        : 'متاسفانه خطایی رخ داده است!';
    if (doMore != null) doMore();
  }

  @protected
  @action
  void onWarn({@required String warn, Function doMore}) {
    print('store onWarn, error: $warn');
    setStatus(StoreStatus.warn);
    errorStore.snackError = (warn != null && warn.isNotEmpty)
        ? warn
        : 'متاسفانه خطایی رخ داده است!';
    if (doMore != null) doMore();
  }

  @protected
  @action
  void onEmpty({Function doMore}) {
    print('store onEmpty');
    setStatus(StoreStatus.empty);
    if (doMore != null) doMore();
  }

  @protected
  @action
  void setStatus(StoreStatus status) {
    print('storeStatus: $status');
    _status = status;
  }

  @action
  void resetSuccessSnack() {
    successSnack = null;
  }

  @action
  void resetInfoSnack() {
    infoSnack = null;
  }

  @action
  void resetSnacks() {
    resetInfoSnack();
    resetSuccessSnack();
  }
}
