# cora_api.model.CampaignDetailModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**brandName** | **String** |  | 
**brandTagline** | **String** |  | 
**campaignId** | **String** |  | 
**fee** | **int** |  | 
**headline** | **String** |  | 
**kind** | **String** |  | 
**mustInclude** | **List<String>** | 꼭 담을 것. | [default to const []]
**myDecision** | [**SavedDecision**](SavedDecision.md) | 내가 저장한 결정(관심 또는 보류). 결정하지 않았으면 null. 넘긴 카드는 상세가 404라서 PASS는 나오지 않는다. | 
**notRequired** | [**List<NotRequired>**](NotRequired.md) | 요구하지 않는 것. | [default to const []]
**overlapCount** | **int** | \"내 협업 원칙과 N개가 겹쳐요\"의 N(reasons의 개수). | 
**photoUrl** | **String** |  | 
**productProvided** | **bool** |  | 
**reasons** | [**List<MatchReason>**](MatchReason.md) | 크리에이터의 협업 원칙과 겹치는 규칙. 많을수록 잘 맞는다. | [default to const []]
**startFrom** | [**DateTime**](DateTime.md) | 시작 가능한 날. | 
**tags** | **List<String>** |  | [default to const []]
**trialDays** | [**ProductTrialDays**](ProductTrialDays.md) |  | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


