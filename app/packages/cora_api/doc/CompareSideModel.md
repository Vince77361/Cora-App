# cora_api.model.CompareSideModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**collaborationId** | **String** |  | 
**creatorId** | **String** |  | 
**faceOk** | **bool** | 크리에이터의 원칙 3번: 얼굴 출연이 괜찮은가. | 
**fee** | **int** | 서로 관심이면 최신 판본의 제작비, 아니면 내 제안의 금액, 없으면 null. | 
**feeBand** | [**FeeBand**](FeeBand.md) | fee가 null일 때 앱이 \"30만 원대\"로 보여 주는 희망 제작비 구간. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**name** | **String** |  | 
**perfCap** | **int** |  | 
**photoUrl** | **String** |  | 
**pieces** | **int** |  | 
**productProvided** | **bool** |  | 
**shortName** | **String** | \"{X}의 …\" 꼴이면 X, 아니면 이름 전체. | 
**startDate** | [**DateTime**](DateTime.md) |  | 
**state** | [**InterestState**](InterestState.md) |  | 
**usageRights** | [**BrandUsageRights**](BrandUsageRights.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


