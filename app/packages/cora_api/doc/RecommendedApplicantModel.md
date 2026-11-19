# cora_api.model.RecommendedApplicantModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**applicationId** | **String** | 지원 번호. 전체 크리에이터에서 뽑은 사람(ALL)은 null. | 
**appliedAt** | [**DateTime**](DateTime.md) | 지원한 시각(ISO 8601). 전체 크리에이터에서 뽑은 사람은 null. | 
**creator** | [**CreatorSummaryModel**](CreatorSummaryModel.md) |  | 
**pitch** | **String** | 지원할 때 붙인 한 줄. 없으면 null. | 
**reasons** | **List<String>** | 추천 이유. 점수에 쓴 사실만 담는다. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


