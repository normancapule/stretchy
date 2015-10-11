require 'spec_helper'

module Stretchy
  describe DottableHash do

    let(:undotted) {{
      root: {
        parent: {
          child: 'leaf'
        },
        leaf: 'parentleaf'
      },
      alsoroot: 'rootleaf'
    }}

    let(:dotted) {{
      'root.parent.child' => 'leaf',
      'root.leaf'         => 'parentleaf',
      'alsoroot'          => 'rootleaf'
    }}

    describe '.to_dotted' do
      subject { described_class.to_dotted undotted }

      it 'produces a dotted hash' do
        expect(subject).to include(dotted)
      end
    end

    describe '.to_undotted' do
      subject { described_class.to_undotted dotted}

      it 'produces an undotted hash' do
        expect(subject).to include(undotted)
      end
    end

    describe '#to_dotted' do
      subject { described_class[undotted].to_dotted }

      it 'produces a dotted hash' do
        expect(subject).to include(dotted)
      end
    end

    describe '#to_undotted' do
      subject { described_class[dotted].to_undotted }

      it 'produces an undotted hash' do
        expect(subject).to include(undotted)
      end
    end
  end
end
