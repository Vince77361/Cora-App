# cora_api.model.OfferTermsModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**fixedCash** | **int** | 고정 현금(원). 없으면 0. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**maxCashBurden** | **int** | 최대 현금 부담. 고정 현금 + 조회수 수당 상한이다. | 
**perViewCap** | **int** | 조회수 수당 상한(원). 수당이 없으면 null. | 
**pieces** | **int** | 콘텐츠 편 수. 오퍼는 지금 한 편이다. | 
**settlementMethod** | [**SettlementMethod**](SettlementMethod.md) |  | 
**usageRights** | [**UsageRights**](UsageRights.md) |  | 
**viewRatePerThousand** | **int** | 조회수 수당 단가. 1,000회당 원이다. 수당이 없으면 null. | 
**voucherName** | **String** |  | 
**voucherPeople** | **int** |  | 
**voucherValue** | **int** |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


