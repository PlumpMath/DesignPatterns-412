require 'rspec'
require 'Patterns/version'
include Patterns
require File.expand_path('../../test', __FILE__) +'/test_env.rb'

describe 'CommandTests' do

  it 'Creates a file, verifies it exists, and then deletes a file' do

    path = '/tmp/test.txt'
    create_file = Patterns::CreateFile.new(path, 'Testing create file.')
    create_file.execute
    expect(File.exists?(path)).to eql(true)
    create_file.undo
    expect(File.exists?(path)).to eql(false)

  end

  it 'Deletes a file, stores its data, and then undoes the operation' do

    path = '/tmp/test.txt'
    `touch #{path}`
    delete_file = Patterns::DeleteFile.new(path)
    delete_file.execute
    expect(File.exists?(path)).to eql(false)

    delete_file.undo
    expect(File.exists?(path)).to eql(true)

  end

  it 'Copies a file from a source path to a target path' do
    source = '/tmp/test.txt'
    target = '/tmp/test2.txt'

    f = File.open(source, 'w')
    data = 'Testing copy file command'
    f.write(data)
    f.close

    copy_file = Patterns::CopyFile.new(source, target)
    copy_file.execute
    source_data = File.read(source)
    target_data = File.read(target)

    expect(source_data).to eql(target_data)

    copy_file.undo

    expect(File.exists?(target)).to eql(false)
  end

  it 'Able to take a list of commands, and execute the next command in the list and undo the last command in the list, in any order' do
    path = '/tmp/test.txt'
    create_file = Patterns::CreateFile.new(path, 'Testing create file.')
    target = '/tmp/test2.txt'
    copy_file = Patterns::CopyFile.new(path, target)
    delete_file = Patterns::DeleteFile.new(path)

    command_list = Patterns::CommandList.new
    command_list.add_commands([create_file, copy_file, delete_file])

    expect(command_list.next_status).to eql('initialized')
    expect(command_list.next_description).to eql('Create File: /tmp/test.txt')

    command_list.execute_next

    expect(command_list.last_status).to eql('Execution completed: Create File: /tmp/test.txt')
    expect(command_list.last_description).to eql('Create File: /tmp/test.txt')
    expect(command_list.next_status).to eql('initialized')
    expect(command_list.next_description).to eql('Copy File: /tmp/test.txt to file: /tmp/test2.txt')

    expect(File.exists?(path)).to eql(true)
    command_list.undo_last

    expect(command_list.last_status).to eql('No commands have been executed yet')
    expect(command_list.last_description).to eql('No commands have been executed yet')
    expect(command_list.next_status).to eql('Undo completed: Create File: /tmp/test.txt')
    expect(command_list.next_description).to eql('Create File: /tmp/test.txt')

    expect(File.exists?(path)).to eql(false)
    command_list.execute_next

    expect(command_list.last_status).to eql('Execution completed: Create File: /tmp/test.txt')
    expect(command_list.last_description).to eql('Create File: /tmp/test.txt')
    expect(command_list.next_status).to eql('initialized')
    expect(command_list.next_description).to eql('Copy File: /tmp/test.txt to file: /tmp/test2.txt')
    expect(File.exists?(path)).to eql(true)
    command_list.execute_next

    expect(command_list.last_status).to eql('Execution completed: Copy File: /tmp/test.txt to file: /tmp/test2.txt')
    expect(command_list.last_description).to eql('Copy File: /tmp/test.txt to file: /tmp/test2.txt')
    expect(command_list.next_status).to eql('initialized')
    expect(command_list.next_description).to eql('Delete File: /tmp/test.txt')
    command_list.execute_next

    expect command_list.last_status == 'Execution completed: Delete File: /tmp/test.txt'
    expect command_list.last_description == 'Delete File: /tmp/test.txt'
    expect command_list.next_status == 'No more commands in list'
    expect command_list.next_description == 'No more commands in list'
    expect File.exists?(path) == false

  end

  command_list_output = ''
  it 'Takes a list of commands and executes all of them, reports their descriptions and statuses, then undoes them' do

    path = '/tmp/test.txt'
    create_file = Patterns::CreateFile.new(path, 'Testing create file.')
    target = '/tmp/test2.txt'
    copy_file = Patterns::CopyFile.new(path, target)
    delete_file = Patterns::DeleteFile.new(path)

    command_list = Patterns::CommandList.new
    command_list.add_commands([create_file, copy_file, delete_file])

    command_list_output << command_list.description
    command_list.execute
    expect(File.exists?(path)).to eql(false)
    expect(File.exists?(target)).to eql(true)
    command_list_output << command_list.status
    command_list.undo
    command_list_output << command_list.status
    expect(File.exists?(target)).to eql(false)
  end

  it 'Prints the descriptions and statuses of the command list test' do
    expect{puts command_list_output}.to output.to_stdout
  end

end