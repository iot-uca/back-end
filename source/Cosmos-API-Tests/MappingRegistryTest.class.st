Class {
	#name : #MappingRegistryTest,
	#superclass : #TestCase,
	#category : #'Cosmos-API-Tests-Model'
}

{ #category : #tests }
MappingRegistryTest >> testDecoderRegistration [

	| mappingRegistry mapping |

	mappingRegistry := MappingRegistry new.

	self
		should: [ mappingRegistry decoderFor: self triggerJsonVersion1dot0dot0MimeType ]
		raise: ObjectNotFound
		withDescription: 'Decoder not found for given schema'.

	mappingRegistry
		register: self triggerJsonEncoderVersion1dot0dot0
		 asDecoderFor: self triggerJsonVersion1dot0dot0MimeType.

	mapping := mappingRegistry decoderFor: self triggerJsonVersion1dot0dot0MimeType.

	self assert: mapping equals: self triggerJsonEncoderVersion1dot0dot0
]

{ #category : #tests }
MappingRegistryTest >> testEncoderRegistration [

	| mappingRegistry mapping |

	mappingRegistry := MappingRegistry new.

	self
		should: [ mappingRegistry encoderFor: self triggerJsonVersion1dot0dot0MimeType ]
		raise: ObjectNotFound
		withDescription: 'Encoder not found for given schema'.

	mappingRegistry
		register: self triggerJsonEncoderVersion1dot0dot0
		 asEncoderFor: self triggerJsonVersion1dot0dot0MimeType.

	mapping := mappingRegistry encoderFor: self triggerJsonVersion1dot0dot0MimeType.

	self assert: mapping equals: self triggerJsonEncoderVersion1dot0dot0
]

{ #category : #accessing }
MappingRegistryTest >> triggerJsonEncoderVersion1dot0dot0 [
	
	^ #triggerJsonEncoderVersion1dot0dot0
]

{ #category : #accessing }
MappingRegistryTest >> triggerJsonVersion1dot0dot0MimeType [

	^ ZnMimeType fromString: 'application/vnd.cosmos.trigger+json; version=1.0.0'
]