# cora_api.model.StoreProposalDto

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
**seriesId** | **String** | 내 시리즈의 id. 이름·형식·설명이 판본에 사본으로 들어간다. 크리에이터만 쓴다. | [optional] 
**usageRights** | [**UsageRights**](UsageRights.md) | 없으면 앞 판본의 사용권. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


