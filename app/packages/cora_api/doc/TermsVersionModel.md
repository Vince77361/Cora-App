# cora_api.model.TermsVersionModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**brandConfirmed** | **bool** | 브랜드가 이 판본을 확인했다. | 
**creatorConfirmed** | **bool** | 크리에이터가 이 판본을 확인했다. | 
**fee** | **int** | 제작비(원, 현금 고정비). | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**maxCash** | **int** | 최대 현금 부담 = 제작비 + 성과 추가 상한(없으면 0). | 
**payoutDays** | **int** | 게시 뒤 지급까지 걸리는 날(7 또는 14). | 
**performance** | [**TermsPerformanceModel**](TermsPerformanceModel.md) | 성과 추가(조회수 수당). 없으면 null. | 
**pieces** | **int** | 편 수(1~3). | 
**productProvided** | **bool** | 제품 제공 여부. | 
**proposedBy** | [**TermsProposer**](TermsProposer.md) | SYSTEM은 서로 관심이 닿을 때 서버가 만든 버전 1이다. | 
**revisionScope** | [**RevisionScope**](RevisionScope.md) |  | 
**startDate** | [**DateTime**](DateTime.md) | 제작 시작. | 
**title** | **String** | 콘텐츠 제목(40자까지). | 
**usageRights** | [**BrandUsageRights**](BrandUsageRights.md) |  | 
**version** | **int** | 판본 번호(1부터). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


