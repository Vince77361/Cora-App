# cora_api.model.RecommendedApplicantsModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**items** | [**List<RecommendedApplicantModel>**](RecommendedApplicantModel.md) | 점수 높은 순 최대 3명. | [default to const []]
**source_** | [**RecommendedSource**](RecommendedSource.md) | APPLICANTS = 이 가게에 지원 중인 사람 중에서, ALL = 지원자가 없어 Cora 크리에이터 전체에서 뽑았다. | 
**totalNew** | **int** | 지원 중인 새 지원자 수. ALL이면 보여 줄 지원자가 없다(보통 0, 지원 줄은 있는데 프로필이 모두 지워졌으면 0보다 클 수 있다). 홈은 이 수가 아니라 source로 가른다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


