# cora_api.model.UpdateCampaignDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**budget** | **int** | 고친 뒤에도 제작비 이상이어야 한다. | [optional] 
**fee** | **int** |  | [optional] 
**format** | [**ContentFormat**](ContentFormat.md) |  | [optional] 
**headline** | **String** |  | [optional] 
**mustInclude** | **List<String>** |  | [optional] [default to const []]
**notRequired** | [**List<NotRequired>**](NotRequired.md) |  | [optional] [default to const []]
**productProvided** | **bool** |  | [optional] 
**startFrom** | [**DateTime**](DateTime.md) | 바꿀 때만 한국 시간 오늘 이후여야 한다. 그대로 보내면 통과한다. | [optional] 
**trialDays** | [**ProductTrialDays**](ProductTrialDays.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


