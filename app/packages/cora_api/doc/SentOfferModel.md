# cora_api.model.SentOfferModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**collaborationId** | **String** | 수락돼 만들어진 협업의 id. 수락 전이면 null. | 
**creator** | [**CreatorSummaryModel**](CreatorSummaryModel.md) |  | 
**id** | **String** |  | 
**myTurn** | **bool** | 사장님이 응답할 차례이면 true. 답을 기다리는 오퍼에만 해당한다. | 
**paymentDaysLeft** | **int** | 수락됐고 아직 결제 기한 전일 때 남은 날(올림). 아니면 null. | 
**sentAt** | [**DateTime**](DateTime.md) | 보낸 시각(ISO 8601). | 
**terms** | [**OfferTermsModel**](OfferTermsModel.md) |  | 
**version** | **int** | 최신 판본의 번호. 수락은 이 번호와 함께 보낸다. | 
**view** | [**OfferView**](OfferView.md) | 사장님에게 보이는 상태. 거절은 30초가 지나야 DECLINED로 보이고 그전에는 WAITING이다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


