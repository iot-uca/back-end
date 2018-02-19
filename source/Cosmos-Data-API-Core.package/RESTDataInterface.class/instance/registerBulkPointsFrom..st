API
registerBulkPointsFrom: aJSON

	^ [ | rawData |

	rawData := (NeoJSONReader on: aJSON readStream) next.

	rawData
		do: [ :rawDataPoint | 
			self
				register: (rawDataPoint at: 'value')
				toStreamNamed: (rawDataPoint at: 'data-stream') ].

	TeaResponse created ]
		on: KeyNotFound
		do: [ :signal | 
			HTTPClientError
				signalBadRequest:
					('{"error":{"code":400,"message":"Expected key <1s> was not found"}'
						expandMacrosWith: signal key) ]