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
**myTurn** | **bool** | 크리에이터가 응답할 차례이면 true. 답을 기다리는 오퍼에만 해당한다. | 
**needsInstagram** | **bool** | 릴스·카드뉴스의 조회수 보상을 받으려면 인스타그램 연동이 필요한데 아직 연동하지 않았으면 true. true인 오퍼는 수락할 수 없다. 기다리는 중(WAITING)이 아닌 오퍼는 항상 false. | 
**receivedAt** | [**DateTime**](DateTime.md) | 도착한 시각(ISO 8601). | 
**store** | [**StoreSummaryModel**](StoreSummaryModel.md) |  | 
**storeIntro** | **String** |  | 
**terms** | [**OfferTermsModel**](OfferTermsModel.md) |  | 
**version** | **int** | 최신 판본의 번호. 수락은 이 번호와 함께 보낸다. | 
**view** | [**OfferView**](OfferView.md) | 크리에이터에게 보이는 상태. 거절은 바로 DECLINED로 보인다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


