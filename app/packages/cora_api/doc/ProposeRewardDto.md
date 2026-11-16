# cora_api.model.ProposeRewardDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**baseVersion** | **int** | 내가 보고 있던 판본 번호. 최신이 아니면 409 STALE_VERSION이다. | 
**fee** | **int** | 제작비(원). 1만 원 단위, 10000~10000000. | 
**performance** | [**RewardPerformanceDto**](RewardPerformanceDto.md) | 성과 추가. 없으면 null. 블로그 글에는 붙일 수 없다. | [optional] 
**productProvided** | **bool** | 제품 제공 여부. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


