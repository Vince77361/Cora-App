# cora_api.model.CreateCampaignDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**budget** | **int** | 캠페인 예산(원). 1만 원 단위, 제작비 이상. | 
**fee** | **int** | 제작비(원). 1만 원 단위. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**headline** | **String** |  | 
**mustInclude** | **List<String>** | 꼭 담을 것. 최대 3줄, 줄마다 1~20자. | [default to const []]
**notRequired** | [**List<NotRequired>**](NotRequired.md) | 요구하지 않는 것. | [default to const []]
**productProvided** | **bool** |  | 
**startFrom** | [**DateTime**](DateTime.md) | 시작 가능한 날(YYYY-MM-DD). 한국 시간 오늘 이후. | 
**trialDays** | [**ProductTrialDays**](ProductTrialDays.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


