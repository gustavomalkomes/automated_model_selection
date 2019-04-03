files = dir('./tests');
counter = 1;
test_output = {};
for i = 1:length(files)
    if files(i).isdir
        continue
    end
    fprintf([files(i).name,'\n'])
    test_name = files(i).name(1:end-2);
    test_output{counter} = run(eval(test_name));
    counter = counter + 1;
end