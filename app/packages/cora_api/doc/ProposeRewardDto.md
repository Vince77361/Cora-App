# cora_api.model.ProposeRewardDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**baseVersion** | **int** | 내가 보고 있던 판본 번호. 최신이 아니면 409 STALE_VERSION이다. | 
**fee** | **int** | 제작비(원). 1만 원 단위, 10000~10000000. 빠지면 그대로. | [optional] 
**format** | [**ContentFormat**](ContentFormat.md) |  | [optional] 
**payoutDays** | **int** | 게시 뒤 지급까지 걸리는 날(7 또는 14). | [optional] 
**performance** | [**RewardPerformanceDto**](RewardPerformanceDto.md) | 성과 추가. 빠지면 그대로, null이면 끈다. 블로그 글에는 붙일 수 없다. | [optional] 
**pieces** | **int** |  | [optional] 
**productProvided** | **bool** | 제품 제공 여부. 빠지면 그대로. | [optional] 
**revisionScope** | [**RevisionScope**](RevisionScope.md) |  | [optional] 
**startDate** | [**DateTime**](DateTime.md) | 제작 시작(YYYY-MM-DD). 바꾸는 값은 한국 시간 오늘 이후. | [optional] 
**title** | **String** | 콘텐츠 제목(1~40자). 빠지면 그대로. | [optional] 
**usageRights** | [**BrandUsageRights**](BrandUsageRights.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


