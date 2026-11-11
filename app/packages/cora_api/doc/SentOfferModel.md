# cora_api.model.SentOfferModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**creator** | [**CreatorSummaryModel**](CreatorSummaryModel.md) |  | 
**id** | **String** |  | 
**paymentDaysLeft** | **int** | 수락됐고 아직 결제 기한 전일 때 남은 날(올림). 아니면 null. | 
**sentAt** | [**DateTime**](DateTime.md) | 보낸 시각(ISO 8601). | 
**terms** | [**OfferTermsModel**](OfferTermsModel.md) |  | 
**view** | [**OfferView**](OfferView.md) | 사장님에게 보이는 상태. 거절은 30초가 지나야 DECLINED로 보이고 그전에는 WAITING이다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


