# cora_api.model.BrandProposalDto

## Load the model package
```dart
import 'package:cora_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**fee** | **int** | 제작비(원). 1만 원 단위, 10000~10000000. | 
**performance** | [**ProposalPerformanceDto**](ProposalPerformanceDto.md) | 성과 추가. 없으면 null. 캠페인 형식이 블로그 글이면 받지 않는다. | [optional] 
**productProvided** | **bool** | 제품 제공 여부. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


