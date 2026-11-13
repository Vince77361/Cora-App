# cora_api.model.ProposeVersionDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**idea** | **String** | 내 방식의 한 줄 설명. 크리에이터만 쓴다. | [optional] 
**principles** | **List<String>** | 내가 지키는 원칙. 최대 3개, 각 10자까지. 크리에이터만 쓴다. | [optional] [default to const []]
**reward** | [**RewardInputDto**](RewardInputDto.md) |  | 
**usageRights** | [**UsageRights**](UsageRights.md) | 없으면 앞 판본의 사용권. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


