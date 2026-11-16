# cora_api.model.CampaignListCardModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**brandName** | **String** | CAMPAIGN만. | [optional] 
**brandTagline** | **String** | CAMPAIGN만. | [optional] 
**campaignId** | **String** | CAMPAIGN만. | [optional] 
**fee** | **int** | CAMPAIGN만. | [optional] 
**headline** | **String** | 캠페인이면 캠페인 한 줄, 가게면 소개의 첫 문장. | 
**kind** | [**CampaignListCardKind**](CampaignListCardKind.md) |  | 
**otherSido** | **String** | STORE만. 내 활동 지역과 시·도가 다르면 가게의 시·도. | [optional] 
**photoUrl** | **String** | CAMPAIGN만. | [optional] 
**productProvided** | **bool** | CAMPAIGN만. | [optional] 
**reasons** | [**List<MatchReason>**](MatchReason.md) | CAMPAIGN만. 크리에이터의 협업 원칙과 겹치는 규칙. | [optional] [default to const []]
**rewardLine** | **String** | STORE만. 보상 세 요소를 \" + \"로 이은 짧은 글. | [optional] 
**store** | [**StoreSummaryModel**](StoreSummaryModel.md) | STORE만. | [optional] 
**tags** | **List<String>** |  | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


