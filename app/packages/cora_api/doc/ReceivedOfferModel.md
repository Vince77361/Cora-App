# cora_api.model.ReceivedOfferModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**bestShootingTime** | **String** |  | 
**canUndoDecline** | **bool** | 방금 거절해 30초 안에 되돌릴 수 있으면 true. | 
**collaborationId** | **String** | 수락돼 만들어진 협업의 id. 수락 전이면 null. | 
**id** | **String** |  | 
**receivedAt** | [**DateTime**](DateTime.md) | 도착한 시각(ISO 8601). | 
**store** | [**StoreSummaryModel**](StoreSummaryModel.md) |  | 
**storeIntro** | **String** |  | 
**terms** | [**OfferTermsModel**](OfferTermsModel.md) |  | 
**view** | [**OfferView**](OfferView.md) | 크리에이터에게 보이는 상태. 거절은 바로 DECLINED로 보인다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


