require 'rspec'
require 'Patterns/version'
include Patterns
require File.expand_path('../../test', __FILE__) +'/test_env.rb'

describe 'TypeObjectTests' do
  context 'TypeObject assignment' do
    it 'Loads prototype and base type data if it exists for all monster types, or just base type if it does not have a prototype' do

      dragon = Monster.new('dragon')
      high_dragon = Monster.new('high_dragon')

      orc = Monster.new('orc')
      orc_wizard = Monster.new('orc_wizard')

      expect(dragon.health).to eql(100)
      expect(high_dragon.health).to eql(150)
      expect(orc.health).to eql(30)
      expect(orc_wizard.health).to eql(30)

    end

    it 'Raises an exception if the monster type does not exist' do
      expect {Monster.new('zombie')}.to raise_exception(MonsterNotFound)
    end

    it 'Gets a prototype name if it exists, and returns "none" if it does not' do
      high_dragon = Monster.new('high_dragon')
      expect(high_dragon.prototype_name).to eql('dragon')

      dragon = Monster.new('dragon')
      expect(dragon.prototype_name).to eql('none')
    end

    it 'Gives detailed exception information for MonsterNotFound' do
      begin
        Monster.new('zombie')
      rescue Exception => e
        expect {puts e.inspect}.to output.to_stdout
      end
    end
  end

  context 'TypeObject Marshal and Deep Clone Tests' do
    it 'Loads all monster prototypes into memory, clones them, and verifies that their object_id\'s are different' do
      monsters = MonsterPrototypes.new

      dragon = monsters.clone_type('dragon')
      dragon2 = monsters.clone_type('dragon')

      orc = monsters.clone_type('orc_wizard')
      orc2 = monsters.clone_type('orc_wizard')

      expect(dragon.object_id).not_to eql(dragon2.object_id)
      expect(orc.object_id).not_to eql(orc2.object_id)
    end

    it 'Loads all monster prototypes into memory, deep clones them(marshal/unmarshal), and verifies that their prototype object_id\'s are different' do
      monsters = MonsterPrototypes.new

      orc = monsters.clone_type('orc')
      orc2 = monsters.clone_type('orc')

      expect(orc.monster_type.object_id).not_to eql(orc2.monster_type.object_id)
    end

    it 'Demonstrates that a shallow clone is not sufficient for prototyping by showing that the object id\'s for clones are different, but the underlying prototype id\'s are the same' do
      monsters = MonsterPrototypes.new

      orc = monsters.clone_type('orc')
      orc2 = orc.clone

      expect(orc.object_id).not_to eql(orc2.object_id)
      expect(orc.monster_type.object_id).to eql(orc2.monster_type.object_id)
    end

    it 'Demonstrates a better clone method (on the monster class) by showing that all object id\'s are different' do
      orc = Monster.new('orc')
      orc2 = orc.deep_clone

      expect(orc.monster_type.object_id).not_to eql(orc2.monster_type.object_id)
    end

    it 'Raises an UnsupportedType exception if something other than a String or MonsterType is passed to Monster.new' do
      expect {Monster.new(0)}.to raise_exception(UnsupportedType)
      expect {Monster.new(:symbol)}.to raise_exception(UnsupportedType)
      expect {Monster.new('werewolf')}.to raise_exception(MonsterNotFound)
    end

    it 'Create n number of orcs using threads' do
      start_time = Time.now
      orcs = []
      threads = []
      thread_count = 10000
      thread_count.times do |i|
        threads[i] = Thread.new {
          orcs[i] = Monster.new('orc')
        }
      end
      threads.each {|t| t.join}
      total_run_time = Time.now - start_time
      expect(total_run_time).to be_between(0, 40)
    end


    it 'Shows that prototype unmarshalling is relatively fast' do
      start_time = Time.now
      $total_marshal_run_time = 0
      monsters = MonsterPrototypes.new
      num = 100000
      count = 0

      orcs = []
      num.times do
        orcs[count] = monsters.clone_type('orc')
        count += 1
      end

      $total_marshal_run_time = Time.now - start_time
      expect($total_marshal_run_time).to be_between(0, 20)
    end

    it 'Makes actual deep copies of many objects and is faster than cloning a single prototype' do

      orcs = []
      num = 100000
      orc_clones = []
      for i in 0..num
        orcs[i] = Monster.new('orc')
      end

      start_time = Time.now
      count = 0
      orcs.each do |orc|
        orc_clones[count] = orc.deep_clone
        count += 1
      end
      total_run_time = Time.now - start_time
      expect(total_run_time).to be_between(0, $total_marshal_run_time)
    end
  end

  context 'TypeObject Thread Pool Cloning' do
    it 'Clones objects much faster using threads (total_marshal_time / (num_cpus / 2))' do
      start_time = Time.now
      #only safe on a mac, might implement other OS's later
      thread_count = `sysctl -n hw.ncpu`.to_i
      threads = []
      mutex = Mutex.new
      num_orcs = 0
      orcs = []
      orc = Monster.new('orc_wizard')
      retries = 0
      begin
      thread_count.times do |i|
        threads[i] = Thread.new {
          until num_orcs >= 100000
            orcs[num_orcs] = orc.deep_clone
            mutex.synchronize {
              num_orcs += 1
            }
          end
        }
      end
      threads.each {|t| t.join}
      rescue
        if retries > 10
          break
        end
        retries += 1
        retry
      end

      total_run_time = Time.now - start_time
      expect(total_run_time).to be_between(0, $total_marshal_run_time), "Total run time for test: #{total_run_time}. Expected run time to be less than #{$total_marshal_run_time}."
    end
  end

end