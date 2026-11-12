# cora_api.model.WalletEntryModel

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**amount** | **int** | 금액(원). 식사권 줄은 null. | 
**at** | [**DateTime**](DateTime.md) | 줄의 기준 시각. 지급 예정은 정산 시각, 지급 완료는 송금 시각, 보관 중은 보관 시작. | 
**collaborationId** | **String** |  | 
**counterpartName** | **String** | 크리에이터에게는 가게 이름. 읽을 수 없으면 \"가게\"(브랜드 계약은 \"브랜드\"). | 
**format** | [**ContentFormat**](ContentFormat.md) |  | 
**kind** | [**WalletEntryKind**](WalletEntryKind.md) | PAYOUT_SCHEDULED: 정산이 확정되고 송금 전, PAYOUT_DONE: 송금 끝, PAYOUT_FAILED: 송금 실패(운영팀이 확인), HELD: Cora가 보관 중, VOUCHER: 식사권. | 
**pieces** | **int** | 콘텐츠 편 수. 오퍼는 지금 한 편이다. | 
**stage** | [**CollaborationStage**](CollaborationStage.md) |  | 
**views** | **int** | 정산에 쓴 최종 조회수. 지급 줄에서만 값이 있다. | 
**voucherName** | **String** | 식사권 이름. 식사권 줄에서만 값이 있다. | 
**voucherUsed** | **bool** | 링크를 제출해 식사권을 쓴 것으로 보면 true. 식사권 줄에서만 값이 있다. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


