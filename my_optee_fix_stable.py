#!/usr/bin/python2
#
# sudo apt-get install python-bs4

import sys, getopt, os
from bs4 import BeautifulSoup
import re

def usage():
    print("test.py -t <tag> -i <input.xml> -n")
    print("Abort...")
    sys.exit(2)

def git_is_optee_component(git_name):
    if (git_name[0:6] == "optee_"):
        return True
    if (git_name[0:5] == "build"):
        return True
    return False

class InputArgs:
    def __init__(self, input_file, tag):
        if (tag == "" or input_file == ""):
            usage()
        self.input_file = input_file
        self.tag = tag

        input = open(self.input_file)
        self.soup = BeautifulSoup(input, "xml")
        input.close()

    def print_soup(self):
        print(self.soup . prettify())

    def replace_revision(self):
        'Replace revision of OP-TEE components with correct tag'
        for project in self.soup.find_all("project", attrs={"name": git_is_optee_component}):
            project["revision"] = "refs/tags/" + self.tag

    def remove_upstream(self):
        for project in self.soup.find_all("project"):
            del project["upstream"]

    def backup_file(self, backup_file):
        if (os.path.exists(backup_file)):
            print("Error: backup file exists: " +  backup_file)
            sys.exit(3)
        os.rename(self.input_file, backup_file)

    def save(self):
        f = open(self.input_file, "w")
        print >> f, self.soup.prettify()
        f.close()

def main(argv):
    input_file = ''
    tag = ''
    replace_rev = True
    try:
        opts, args = getopt.getopt(argv,"ht:i:n",["tag=","input="])
    except getopt.GetoptError:
        usage()
    for opt, arg in opts:
        if opt == '-h':
            usage()
        elif opt == '-n':
            replace_rev = False
        elif opt in ("-i", "--input"):
            input_file = arg
        elif opt in ("-t", "--tag"):
            tag = arg

    print("New tag is ", tag)
    print("Input file is ", input_file)

    # Fix prettify so that it dumps 2 space for the indentation
    orig_prettify = BeautifulSoup.prettify
    r = re.compile(r'^(\s*)', re.MULTILINE)

    def prettify(self, encoding=None, formatter="minimal", indent_width=2):
        return r.sub(r'\1' * indent_width, orig_prettify(self, encoding, formatter))

    BeautifulSoup.prettify = prettify

    input = InputArgs(input_file, tag)
    if replace_rev:
        input.replace_revision()
    input.remove_upstream()
    input.backup_file(input_file + ".bak")
    input.save()

if __name__ == "__main__":
    main(sys.argv[1:])

