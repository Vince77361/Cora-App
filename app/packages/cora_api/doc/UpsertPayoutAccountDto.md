# cora_api.model.UpsertPayoutAccountDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**accountNumber** | **String** | 계좌번호. 하이픈은 떼고 저장한다. 숫자 10~14자리. | 
**bankCode** | **String** | 은행 코드. GET /payout-account/banks의 code 중 하나. | 
**holderName** | **String** | 예금주 이름. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


