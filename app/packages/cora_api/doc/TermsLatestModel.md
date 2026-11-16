# cora_api.model.TermsLatestModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**fields** | **List<String>** | 크리에이터가 협업 원칙에서 고른 분야의 이름표(고른 순서). 원칙이 없으면 빈 배열. | [default to const []]
**followers** | **int** | 크리에이터가 연동한 인스타그램의 팔로워 수. 연동이 없으면 null. | 
**mine** | **bool** | 최신 판본을 내가 냈다. | 
**myTurn** | **bool** | 최신 판본을 내가 아직 확인하지 않았다. | 
**needsInstagram** | **bool** | 내가 크리에이터이고, 성과 추가가 켜져 있고, 형식이 릴스나 카드뉴스이고, 인스타그램이 연동돼 있지 않다. | 
**notice** | **String** | 크리에이터의 협업 원칙에서 만든 안내 줄. 해당하는 것이 없으면 null. | 
**reasons** | [**List<MatchReason>**](MatchReason.md) | 크리에이터의 협업 원칙과 캠페인이 겹치는 규칙. | [default to const []]
**terms** | [**TermsVersionModel**](TermsVersionModel.md) |  | 
**trialDays** | [**ProductTrialDays**](ProductTrialDays.md) | 캠페인의 제품 사용 기간. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


