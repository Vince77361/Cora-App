# cora_api.model.CampaignModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**budget** | **int** | 이 캠페인에 쓰려는 현금의 합(원). 브랜드만 보는 값이라 크리에이터가 받는 응답에는 넣지 않는다. | 
**fee** | **int** | 크리에이터 한 명에게 주는 현금 고정비의 기본값(원). | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**headline** | **String** |  | 
**id** | **String** |  | 
**mustInclude** | **List<String>** | 꼭 담을 것. 줄마다 20자까지. | [default to const []]
**notRequired** | [**List<NotRequired>**](NotRequired.md) | 요구하지 않는 것. | [default to const []]
**productProvided** | **bool** |  | 
**startFrom** | [**DateTime**](DateTime.md) |  | 
**status** | [**CampaignStatus**](CampaignStatus.md) |  | 
**trialDays** | [**ProductTrialDays**](ProductTrialDays.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


