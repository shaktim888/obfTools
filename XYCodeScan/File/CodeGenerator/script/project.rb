#此文件作废
require 'xcodeproj'
require 'fileutils'

files = Array.new
targetNames = Array.new
$i = 0
$num = $*.length
$groupPath = "Out"
while $i < $num  do
    if $*[$i] == "-f" then
        $i += 1
        files << $*[$i]
    elsif $*[$i] == "-p" then
        $i += 1
        $project_path = $*[$i]
    elsif $*[$i] == "-t" then
        $i += 1
        targetNames << $*[$i]
    elsif $*[$i] == "-g" then
        $i += 1
        $groupPath = $*[$i]
    end
    $i +=1
end
proj = Xcodeproj::Project.open($project_path)

targets = proj.targets.select { |target| 
    targetNames.length <= 0 or targetNames.include? target.name
}

group = proj.main_group.find_subpath($groupPath, true)
for file in files do
    group.set_source_tree('SOURCE_ROOT')
    
    # add file
    file_ref = group.new_reference(file)

    targets.each { 
        |target| 
        target.add_file_references([file_ref])
    }
end
    
proj.save()
