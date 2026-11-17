# cora_api.model.TermsHistoryModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**agreement** | [**TermsAgreement**](TermsAgreement.md) | 최신 판본의 확인 상태. NONE = 아무도 확인하지 않음, WAITING_BRAND = 크리에이터만 확인, WAITING_CREATOR = 브랜드만 확인, AGREED = 양쪽 확인. | 
**editable** | **bool** | 조건 수정 제안을 낼 수 있다: 협의할 수 있는 단계이고 브랜드 결제가 진행 중이 아니다. | 
**versions** | [**List<TermsVersionModel>**](TermsVersionModel.md) | 판본 목록. 최신이 먼저다. | [default to const []]

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


