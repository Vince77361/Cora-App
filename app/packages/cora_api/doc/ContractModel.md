# cora_api.model.ContractModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**brandConsentedAt** | [**DateTime**](DateTime.md) | 결제가 승인돼 체결될 때 채워진다. | 
**brandName** | **String** |  | 
**concludedAt** | [**DateTime**](DateTime.md) |  | 
**creatorConsentedAt** | [**DateTime**](DateTime.md) |  | 
**creatorName** | **String** |  | 
**myConsentTexts** | **List<String>** | 내 쪽 확인란 세 줄. 동의할 때 이 문구를 그대로 보낸다(다르면 400). 계약할 수 없는 상태면 빈 배열. | [default to const []]
**quote** | [**PaymentQuoteModel**](PaymentQuoteModel.md) | 브랜드에게만, 동의하면 결제할 금액(크리에이터 동의 뒤 결제 전). 서버가 계약 사본에서 계산한 값이다. | 
**status** | [**ContractStatus**](ContractStatus.md) | NOT_READY = 양쪽이 같은 판본을 확인하기 전(미리 보기), AWAITING_CREATOR = 합의됨·크리에이터 동의 전, AWAITING_BRAND = 크리에이터 동의 뒤·브랜드 동의(결제) 전, PAYING = 브랜드가 결제 중(결제창을 연 지 60분 안), CONCLUDED = 결제가 승인돼 체결됨. | 
**terms** | [**TermsVersionModel**](TermsVersionModel.md) | 조건. 계약 행이 있으면 동의할 때 만든 사본이고, 없으면 최신 판본(미리 보기)이다. | 
**termsVersion** | **int** | 계약이 담은(미리 보기면 최신) 판본 번호. 판본이 없으면 null. | 
**voidedNotice** | **bool** | 내 동의가 새 판본으로 취소됐고 새 계약이 아직 없다(앱이 \"조건이 바뀌어 동의가 취소됐어요.\" 띠를 보여 준다). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


