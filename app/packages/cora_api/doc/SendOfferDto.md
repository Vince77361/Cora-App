# cora_api.model.SendOfferDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**creatorId** | **String** | 오퍼를 받을 크리에이터의 ID. | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**rewardType** | [**RewardType**](RewardType.md) |  | 
**voucherName** | **String** | 식사권이 보상에 들어갈 때만 쓴다. 없으면 \"2인 식사권\". | [optional] 
**voucherValue** | **int** | 식사권이 보상에 들어갈 때만 쓴다. 없으면 40000. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


